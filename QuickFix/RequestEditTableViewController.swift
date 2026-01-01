//
//  RequestEditTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class RequestEditTableViewController: UITableViewController {

    // MARK: - MUST set before open
        var requestId: String!

        // MARK: - Outlets (Static cells)
        @IBOutlet private weak var reportIdLabel: UILabel!
        @IBOutlet private weak var submissionDateLabel: UILabel!

        @IBOutlet private weak var campusLabel: UILabel!
        @IBOutlet private weak var buildingNumberLabel: UILabel!
        @IBOutlet private weak var classNumberLabel: UILabel!

        @IBOutlet private weak var problemDescriptionLabel: UILabel!
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
            guard let requestId else { return }

            listener = db.collection("StudentRepairRequests")
                .document(requestId)
                .addSnapshotListener { [weak self] snap, err in
                    guard let self else { return }
                    if let err { print("Firestore:", err); return }
                    guard let d = snap?.data() else { return }

                    // Report id
                    self.reportIdLabel.text = (d["reportId"] as? String)
                        ?? (d["reportID"] as? String)
                        ?? (d["requestNumber"] as? String)
                        ?? "-"

                    // Submission date (fallback to createdAt)
                    if let ts = (d["submissionDate"] as? Timestamp) ?? (d["createdAt"] as? Timestamp) {
                        self.submissionDateLabel.text = self.format(ts.dateValue())
                    } else {
                        self.submissionDateLabel.text = "-"
                    }

                    // Location
                    self.campusLabel.text = (d["campus"] as? String) ?? "-"
                    self.buildingNumberLabel.text = self.anyToString(d["buildingNumber"]) ?? "-"
                    self.classNumberLabel.text = self.anyToString(d["classNumber"]) ?? "-"

                    // Problem
                    self.problemDescriptionLabel.text = (d["problemDescription"] as? String)
                        ?? (d["issue"] as? String)
                        ?? "-"

                    // Image (URL or base64)
                    if let url = d["imageUrl"] as? String, !url.isEmpty {
                        self.loadImageFromURL(url)
                    } else if let b64 = d["imageBase64"] as? String, !b64.isEmpty {
                        self.issueImageView.image = self.decodeBase64Image(b64)
                    } else {
                        self.issueImageView.image = UIImage(systemName: "photo")
                    }

                    // Auto resize for long text in static table view
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                }
        }

        private func anyToString(_ v: Any?) -> String? {
            if let s = v as? String { return s }
            if let i = v as? Int { return String(i) }
            if let d = v as? Double { return String(Int(d)) }
            return nil
        }

        private func format(_ date: Date) -> String {
            let f = DateFormatter()
            f.dateStyle = .medium
            f.timeStyle = .short
            return f.string(from: date)
        }

        // MARK: - Actions
        @IBAction private func didTapAccept(_ sender: UIButton) {
            updateDecision(status: "accepted")
        }

        @IBAction private func didTapReject(_ sender: UIButton) {
            updateDecision(status: "rejected")
        }

        private func updateDecision(status: String) {
            guard let requestId else { return }

            let ref = db.collection("StudentRepairRequests").document(requestId)
            ref.updateData([
                "decision": status,
                "decisionAt": Timestamp(date: Date())
            ]) { [weak self] err in
                if let err {
                    self?.showAlert("Error", err.localizedDescription)
                } else {
                    self?.showAlert("Done", "Request \(status).")
                }
            }
        }

        private func showAlert(_ title: String, _ msg: String) {
            let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }

        // MARK: - Image loading
        private func loadImageFromURL(_ urlString: String) {
            guard let url = URL(string: urlString) else { return }

            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async {
                    self.issueImageView.image = img
                }
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
