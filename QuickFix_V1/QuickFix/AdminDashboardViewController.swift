//
//  AdminDashboardViewController.swift
//  QuickFix
//

import UIKit
import FirebaseFirestore

final class AdminDashboardViewController: UIViewController {
   


    @IBOutlet weak var pendingStatusLabel: UILabel!
    @IBOutlet weak var inProgressStatusLabel: UILabel!
    @IBOutlet weak var completedStatusLabel: UILabel!

    @IBOutlet weak var totalRequestsLabel: UILabel!
    @IBOutlet weak var pendingLabel: UILabel!
    @IBOutlet weak var inProgressLabel: UILabel!
    @IBOutlet weak var completedLabel: UILabel!

    @IBOutlet weak var donutChartView: DonutChartView!
    @IBOutlet var cardViews: [UIView]!

    private let db = Firestore.firestore()
    private let requestsCollection = "StudentRepairRequests"

    private var requestsListener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        UserDefaults.standard.removeObject(forKey: "didSeedDemoData")

            view.backgroundColor = .systemGroupedBackground
            donutChartView.segments = []
            cardViews?.forEach { $0.applyCardStyle() }
            startDashboardListener()


       
        view.backgroundColor = .systemGroupedBackground

        donutChartView.segments = []
        cardViews?.forEach { $0.applyCardStyle() }

        startDashboardListener()
    }

    deinit {
        requestsListener?.remove()
    }

    @objc private func didTapBell() {
        let alert = UIAlertController(title: "Notifications", message: "Tapped bell.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func startDashboardListener() {
        requestsListener?.remove()

        requestsListener = db.collection(requestsCollection).addSnapshotListener { [weak self] snap, err in
            guard let self else { return }

            if let err = err {
                print("Dashboard listener error:", err)
                return
            }

            let docs = snap?.documents ?? []

            var pending = 0
            var inProgress = 0
            var completed = 0

            for doc in docs {
                let status = (doc.data()["status"] as? String ?? "").lowercased()
                switch status {
                case "pending":
                    pending += 1
                case "in_progress":
                    inProgress += 1
                case "completed":
                    completed += 1
                default:
                    break
                }
            }

            let total = docs.count

            DispatchQueue.main.async {
                self.totalRequestsLabel.text = "\(total)"

                self.pendingLabel.text = "\(pending)"
                self.inProgressLabel.text = "\(inProgress)"
                self.completedLabel.text = "\(completed)"

                self.pendingStatusLabel.text = "Pending (\(pending))"
                self.inProgressStatusLabel.text = "In Progress (\(inProgress))"
                self.completedStatusLabel.text = "Completed (\(completed))"

                self.donutChartView.segments = [
                    .init(value: CGFloat(pending), color: .systemOrange),
                    .init(value: CGFloat(inProgress), color: .systemBlue),
                    .init(value: CGFloat(completed), color: .systemGreen)
                ]
            }
        }
    }
}
