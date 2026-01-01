//
//  PendingTasksTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class PendingTasksTableViewController: UITableViewController {
    
    // MARK: - MUST set before open
        var ticketDocId: String!

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

        @IBOutlet private weak var acceptButton: UIButton!
        @IBOutlet private weak var rejectButton: UIButton!

        private let db = Firestore.firestore()
        private var listener: ListenerRegistration?

        override func viewDidLoad() {
            super.viewDidLoad()
            styleUI()
            startListening()
        }

        deinit { listener?.remove() }

        // MARK: - UI
        private func styleUI() {
            issueImageView.layer.cornerRadius = 10
            issueImageView.clipsToBounds = true

            acceptButton.layer.cornerRadius = 10
            rejectButton.layer.cornerRadius = 10
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

                    self.ticketIdLabel.text = ticketId
                    self.ticketNameLabel.text = name
                    self.locationLabel.text = location
                    self.issueLabel.text = issue
                    self.urgencyLabel.text = urgency
                    self.assignedToLabel.text = assignedTo
                    self.statusLabel.text = self.statusTitle(rawStatus)

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

        private func statusTitle(_ raw: String) -> String {
            switch raw {
            case "completed": return "Completed"
            case "in_progress": return "In Progress"
            default: return "Pending"
            }
        }

        private func format(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }

        // MARK: - Actions
        @IBAction private func didTapAccept(_ sender: UIButton) {
            // Change this if you want "accepted" instead of "in_progress"
            updateStatus(to: "in_progress")
        }

        @IBAction private func didTapReject(_ sender: UIButton) {
            updateStatus(to: "rejected")
        }

        private func updateStatus(to newStatus: String) {
            guard let ticketDocId else { return }

            acceptButton.isEnabled = false
            rejectButton.isEnabled = false

            db.collection("StudentRepairRequests")
                .document(ticketDocId)
                .updateData([
                    "status": newStatus,
                    "statusUpdatedAt": Timestamp(date: Date())
                ]) { [weak self] err in
                    guard let self else { return }
                    self.acceptButton.isEnabled = true
                    self.rejectButton.isEnabled = true

                    if let err {
                        self.showAlert("Error", err.localizedDescription)
                    } else {
                        self.showAlert("Done", "Status updated.")
                    }
                }
        }

        private func showAlert(_ title: String, _ msg: String) {
            let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }

        // MARK: - Image
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

