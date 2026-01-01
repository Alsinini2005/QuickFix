//
//  RatingTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class RatingTableViewController: UITableViewController {

    // MARK: - Set before open
        var requestId: String!

        // MARK: - Outlets (Static cells)
        @IBOutlet private weak var requestNumberLabel: UILabel!
        @IBOutlet private weak var requestNameLabel: UILabel!
        @IBOutlet private weak var locationLabel: UILabel!
        @IBOutlet private weak var issueLabel: UILabel!
        @IBOutlet private weak var statusLabel: UILabel!
        @IBOutlet private weak var createdAtLabel: UILabel!

        @IBOutlet private weak var commentTextView: UITextView!

        @IBOutlet private weak var star1: UIButton!
        @IBOutlet private weak var star2: UIButton!
        @IBOutlet private weak var star3: UIButton!
        @IBOutlet private weak var star4: UIButton!
        @IBOutlet private weak var star5: UIButton!

        @IBOutlet private weak var submitButton: UIButton!

        private let db = Firestore.firestore()
        private var listener: ListenerRegistration?

        private var rating: Int = 0

        override func viewDidLoad() {
            super.viewDidLoad()
            setupUI()
            startListening()
        }

        deinit { listener?.remove() }

        private func setupUI() {
            commentTextView.layer.borderWidth = 1
            commentTextView.layer.borderColor = UIColor.systemGray4.cgColor
            commentTextView.layer.cornerRadius = 8

            [star1, star2, star3, star4, star5].enumerated().forEach { i, b in
                b?.tag = i + 1
                b?.titleLabel?.font = .systemFont(ofSize: 28)
            }
            updateStars()

            submitButton.layer.cornerRadius = 10
        }

        private func startListening() {
            guard let requestId else { return }

            listener = db.collection("StudentRepairRequests")
                .document(requestId)
                .addSnapshotListener { [weak self] snap, err in
                    guard let self else { return }
                    if let err { print("Firestore:", err); return }
                    guard let d = snap?.data() else { return }

                    let reqNo = (d["requestNumber"] as? String) ?? (d["requestId"] as? String) ?? "-"
                    let reqName = (d["requestName"] as? String) ?? (d["title"] as? String) ?? "-"
                    let loc = (d["location"] as? String) ?? "-"
                    let issue = (d["issue"] as? String) ?? (d["problem"] as? String) ?? "-"
                    let rawStatus = (d["status"] as? String) ?? "pending"

                    self.requestNumberLabel.text = reqNo
                    self.requestNameLabel.text = reqName
                    self.locationLabel.text = loc
                    self.issueLabel.text = issue
                    self.statusLabel.text = self.mapStatus(rawStatus)

                    if let ts = d["createdAt"] as? Timestamp {
                        self.createdAtLabel.text = self.format(ts.dateValue())
                    } else {
                        self.createdAtLabel.text = "-"
                    }
                }
        }

        private func mapStatus(_ raw: String) -> String {
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

        // MARK: - Stars
        @IBAction private func didTapStar(_ sender: UIButton) {
            rating = sender.tag
            updateStars()
        }

        private func updateStars() {
            let buttons = [star1, star2, star3, star4, star5]
            for (i, b) in buttons.enumerated() {
                b?.setTitle((i + 1) <= rating ? "★" : "☆", for: .normal)
            }
        }

        // MARK: - Submit
        @IBAction private func didTapSubmit(_ sender: UIButton) {
            guard let requestId else { return }

            if rating == 0 {
                showAlert("Rating", "Please select a star rating.")
                return
            }

            sender.isEnabled = false

            let comment = commentTextView.text.trimmingCharacters(in: .whitespacesAndNewlines)
            let now = Timestamp(date: Date())

            let payload: [String: Any] = [
                "rating": rating,
                "comment": comment,
                "ratedAt": now
            ]

            let reqRef = db.collection("StudentRepairRequests").document(requestId)

            reqRef.collection("ratings").addDocument(data: payload) { [weak self] err in
                guard let self else { return }
                if let err {
                    sender.isEnabled = true
                    self.showAlert("Error", err.localizedDescription)
                    return
                }

                reqRef.updateData([
                    "lastRating": self.rating,
                    "lastComment": comment,
                    "lastRatedAt": now
                ]) { _ in
                    sender.isEnabled = true
                    self.showAlert("Done", "Thanks for your feedback!")
                }
            }
        }

        private func showAlert(_ title: String, _ msg: String) {
            let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            present(a, animated: true)
        }
}
