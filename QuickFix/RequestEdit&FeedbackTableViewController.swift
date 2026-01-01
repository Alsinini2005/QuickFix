//
//  RequestEdit&FeedbackTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class RequestEdit_FeedbackTableViewController: UITableViewController {
    
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

       @IBOutlet private weak var feedbackButton: UIButton!
       @IBOutlet private weak var editButton: UIButton!

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

           feedbackButton.layer.cornerRadius = 10
           editButton.layer.cornerRadius = 10
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

                   self.reportIdLabel.text = (d["reportId"] as? String)
                       ?? (d["reportID"] as? String)
                       ?? (d["requestNumber"] as? String)
                       ?? "-"

                   if let ts = (d["submissionDate"] as? Timestamp) ?? (d["createdAt"] as? Timestamp) {
                       self.submissionDateLabel.text = self.format(ts.dateValue())
                   } else {
                       self.submissionDateLabel.text = "-"
                   }

                   self.campusLabel.text = (d["campus"] as? String) ?? "-"
                   self.buildingNumberLabel.text = self.anyToString(d["buildingNumber"]) ?? "-"
                   self.classNumberLabel.text = self.anyToString(d["classNumber"]) ?? "-"

                   self.problemDescriptionLabel.text = (d["problemDescription"] as? String)
                       ?? (d["issue"] as? String)
                       ?? "-"

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

       // MARK: - Buttons
       @IBAction private func didTapFeedback(_ sender: UIButton) {
           // Option A: Segue from storyboard
           performSegue(withIdentifier: "toFeedback", sender: nil)
       }

       @IBAction private func didTapEdit(_ sender: UIButton) {
           // Option A: Segue from storyboard
           performSegue(withIdentifier: "toEdit", sender: nil)
       }

       // MARK: - Navigation
       override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
           if segue.identifier == "toFeedback" {
               // Change class name if yours is different
               if let vc = segue.destination as? RateServiceStaticTableViewController {
                   vc.requestId = requestId
               }
           } else if segue.identifier == "toEdit" {
               // Change class name if yours is different
               if let vc = segue.destination as? EditRequestViewController {
                   vc.requestId = requestId
               }
           }
       }

       // MARK: - Image loading
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
