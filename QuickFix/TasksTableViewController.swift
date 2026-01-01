//
//  TasksTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class TasksTableViewController: UITableViewController {

    // MARK: - MUST set before open
        var ticketDocId: String!   // Firestore document id

        // MARK: - Outlets (Static cells)
        @IBOutlet private weak var ticketIdLabel: UILabel!
        @IBOutlet private weak var ticketNameLabel: UILabel!
        @IBOutlet private weak var locationLabel: UILabel!
        @IBOutlet private weak var issueLabel: UILabel!
        @IBOutlet private weak var statusLabel: UILabel!
        @IBOutlet private weak var urgencyLabel: UILabel!
        @IBOutlet private weak var createdAtLabel: UILabel!
        @IBOutlet private weak var assignedToLabel: UILabel!

        @IBOutlet private weak var issueImageView: UIImageView!

        // Popup button (Status)
        @IBOutlet private weak var statusPopupButton: UIButton!

        @IBOutlet private weak var submitButton: UIButton!

        private let db = Firestore.firestore()
        private var listener: ListenerRegistration?

        private var selectedStatus: String = "pending" // raw value

        override func viewDidLoad() {
            super.viewDidLoad()
            styleUI()
            startListening()
            setupStatusMenu(current: selectedStatus)
        }

        deinit { listener?.remove() }

        // MARK: - UI
        private func styleUI() {
            issueImageView.layer.cornerRadius = 10
            issueImageView.clipsToBounds = true

            submitButton.layer.cornerRadius = 10

            statusPopupButton.layer.cornerRadius = 8
            statusPopupButton.layer.borderWidth = 1
            statusPopupButton.layer.borderColor = UIColor.systemGray4.cgColor
            statusPopupButton.contentHorizontalAlignment = .left
            statusPopupButton.contentEdgeInsets = UIEdgeInsets(top: 10, left: 12, bottom: 10, right: 12)
        }

        // MARK: - Firestore
        private func startListening() {
            guard let ticketDocId else { return }

            listener = db.collection("StudentRepairRequests")
                .document(ticketDocId)
                .addSnapshotListener { [weak self] snap, err in
                    guard let self else { return }
                    if let err { print("Firestore:", err); return }
                    guard let d = snap?.data() else { return }

                    let docId = snap?.documentID ?? "-"
                    let ticketId = (d["ticketId"] as? String) ?? (d["requestNumber"] as? String) ?? docId
                    let name = (d["ticketName"] as? String) ?? (d["requestName"] as? String) ?? (d["title"] as? String) ?? "-"
                    let location = (d["location"] as? String) ?? "-"
                    let issue = (d["issue"] as? String) ?? (d["problem"] as? String) ?? "-"
                    let urgency = (d["urgency"] as? String) ?? (d["priority"] as? String) ?? "-"
                    let assignedTo = (d["assignedTo"] as? String) ?? (d["assignedToName"] as? String) ?? "-"

                    let rawStatus = (d["status"] as? String) ?? "pending"
                    self.selectedStatus = rawStatus

                    self.ticketIdLabel.text = ticketId
                    self.ticketNameLabel.text = name
                    self.locationLabel.text = location
                    self.issueLabel.text = issue
                    self.urgencyLabel.text = urgency
                    self.assignedToLabel.text = assignedTo

                    self.statusLabel.text = self.statusTitle(rawStatus)
                    self.statusPopupButton.setTitle(self.statusTitle(rawStatus), for: .normal)
                    self.setupStatusMenu(current: rawStatus)

                    if let ts = d["createdAt"] as? Timestamp {
                        self.createdAtLabel.text = self.format(ts.dateValue())
                    } else {
                        self.createdAtLabel.text = "-"
                    }

                    if let url = d["imageUrl"] as? String, !url.isEmpty {
                        self.loadImageFromURL(url)
                    } else if let b64 = d["imageBase64"] as? String, !b64.isEmpty {
                        self.issueImageView.image = self.decodeBase64Image(b64)
                    } else {
                        self.issueImageView.image = UIImage(systemName: "photo")
                    }

                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
        }

        // MARK: - Status Menu
        private func setupStatusMenu(current: String) {
            let options: [(String, String)] = [
                ("pending", "Pending"),
                ("in_progress", "In Progress"),
                ("completed", "Completed")
            ]

            let actions = options.map { raw, title in
                UIAction(title: title, state: (raw == current ? .on : .off)) { [weak self] _ in
                    guard let self else { return }
                    self.selectedStatus = raw
                    self.statusPopupButton.setTitle(title, for: .normal)
                }
            }

            statusPopupButton.menu = UIMenu(title: "Status", children: actions)
            statusPopupButton.showsMenuAsPrimaryAction = true
        }

        private func statusTitle(_ raw: String) -> String {
            switch raw {
            case "completed": return "Completed"
            case "in_progress": return "In Progress"
            default: return "Pending"
            }
        }

        // MARK: - Submit
        @IBAction private func didTapSubmit(_ sender: UIButton) {
            guard let ticketDocId else { return }

            sender.isEnabled = false
            let ref = db.collection("StudentRepairRequests").document(ticketDocId)

            ref.updateData([
                "status": selectedStatus,
                "statusUpdatedAt": Timestamp(date: Date())
            ]) { [weak self] err in
                guard let self else { return }
                sender.isEnabled = true
                if let err {
                    self.showAlert("Error", err.localizedDescription)
                } else {
                    self.statusLabel.text = self.statusTitle(self.selectedStatus)
                    self.showAlert("Done", "Status updated.")
                }
            }
        }

        // MARK: - Helpers
        private func format(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }

        private func showAlert(_ title: String, _ msg: String) {
            let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }

        private func loadImageFromURL(_ urlString: String) {
            guard let url = URL(string: urlString) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.issueImageView.image = img }
            }.resume()
        }

        private func decodeBase64Image(_ base64: String) -> UIImage? {
            let cleaned = base64
                .replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                .replacingOccurrences(of: "data:image/png;base64,", with: "")
            guard let data = Data(base64Encoded: cleaned) else { return nil }
            return UIImage(data: data)
        }
}
