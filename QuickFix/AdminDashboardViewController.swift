//
//  AdminDashboardViewController.swift
//  QuickFix
//

import UIKit
import FirebaseFirestore

final class AdminDashboardViewController: UIViewController {
   
   
    
    /*func seedStudentRepairRequests() {
        let db = Firestore.firestore()
        let col = db.collection("StudentRepairRequests")

        let items: [(String, [String: Any])] = [
            ("Request 2", [
                "title": "Wifi not working",
                "problemDescription": "Wifi not working",
                "campus": "Campus A",
                "building": 34,
                "classroom": 12,
                "status": "pending",
                "userId": "u4y8w4",
     "imageUrl":"https://res.cloudinary.com/userrequest/image/upload/v1767340340/pdadm0w5sxsxg5lgc20q.jpg",
                "createdAt": Timestamp(date: Date())
            ]),
            ("Request 3", [
                "title": "AC broken",
                "problemDescription": "Air conditioner not cooling",
                "campus": "Campus B",
                "building": 21,
                "classroom": 5,
                "status": "in_progress",
                "userId": "student_002",
                "createdAt": Timestamp(date: Date())
     "imageUrl":"https://res.cloudinary.com/userrequest/image/upload/v1767340340/pdadm0w5sxsxg5lgc20q.jpg",
            ]),
            ("Request 4", [
                "title": "Projector issue",
                "problemDescription": "Projector not turning on",
                "campus": "Campus A",
                "building": 10,
                "classroom": 3,
                "status": "completed",
                "userId": "student_003",
                "createdAt": Timestamp(date: Date())
     "imageUrl":"https://res.cloudinary.com/userrequest/image/upload/v1767340340/pdadm0w5sxsxg5lgc20q.jpg",
            ])
        ]

        items.forEach { docId, data in
            col.document(docId).setData(data) { err in
                if let err = err { print("❌ StudentRepairRequests/\(docId):", err) }
                else { print("✅ StudentRepairRequests/\(docId) added") }
            }
        }
    }

    
    func seedMoreTaskAssignments() {
        let db = Firestore.firestore()
        let col = db.collection("taskAssignments")

        let items: [(String, [String: Any])] = [
            ("Assign_1", [
                "technicianName": "ahmed ali",
                "requestId": "Request 2",
                "status": "pending",
                "assignedAt": Timestamp(date: Date())
            ]),
            ("Assign_2", [
                "technicianName": "sara khaled",
                "requestId": "Request 3",
                "status": "in_progress",
                "assignedAt": Timestamp(date: Date())
            ]),
            ("Assign_3", [
                "technicianName": "mohammed ali",
                "requestId": "Request 4",
                "status": "completed",
                "assignedAt": Timestamp(date: Date())
            ])
        ]

        items.forEach { docId, data in
            col.document(docId).setData(data) { err in
                if let err = err { print("❌ taskAssignments/\(docId):", err) }
                else { print("✅ taskAssignments/\(docId) added") }
            }
        }
    }

    func seedMoreTechnicians() {
        let db = Firestore.firestore()
        let col = db.collection("technicians")

        let items: [(String, [String: Any])] = [
            ("tech_001", [
                "techName": "ahmed",
                "specialization": "electrical",
                "isActive": true,
                "completedTasks": 12,
                "totalTasks": 20
            ]),
            ("tech_002", [
                "techName": "sara",
                "specialization": "hardware",
                "isActive": true,
                "completedTasks": 7,
                "totalTasks": 15
            ]),
            ("tech_003", [
                "techName": "khaled",
                "specialization": "networking",
                "isActive": false,
                "completedTasks": 30,
                "totalTasks": 40
            ])
        ]

        items.forEach { docId, data in
            col.document(docId).setData(data) { err in
                if let err = err { print("❌ technicians/\(docId):", err) }
                else { print("✅ technicians/\(docId) added") }
            }
        }
    }



    private func seedAllOnce() {
        seedStudentRepairRequests()
        seedMoreTaskAssignments()
        seedMoreTechnicians()

      
    }



 


*/

    @IBOutlet weak var techOfWeekRankLabel: UILabel!
    @IBOutlet weak var techOfWeekSubtitleLabel: UILabel!
    @IBOutlet weak var techOfWeekNameLabel: UILabel!

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
       // seedAllOnce()   // run seeding safely one time
        UserDefaults.standard.removeObject(forKey: "didSeedDemoData") // TEMP
         //   seedAllOnce()

            view.backgroundColor = .systemGroupedBackground
            donutChartView.segments = []
            cardViews?.forEach { $0.applyCardStyle() }
            startDashboardListener()


       
        view.backgroundColor = .systemGroupedBackground

        let bell = UIBarButtonItem(
            image: UIImage(systemName: "bell"),
            style: .plain,
            target: self,
            action: #selector(didTapBell)
        )
        navigationItem.rightBarButtonItem = bell
        navigationController?.navigationBar.prefersLargeTitles = true

        donutChartView.segments = []

        // Safe styling even if not connected
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
                // Labels
                self.totalRequestsLabel.text = "\(total)"

                self.pendingLabel.text = "\(pending)"
                self.inProgressLabel.text = "\(inProgress)"
                self.completedLabel.text = "\(completed)"

                self.pendingStatusLabel.text = "Pending (\(pending))"
                self.inProgressStatusLabel.text = "In Progress (\(inProgress))"
                self.completedStatusLabel.text = "Completed (\(completed))"

                // Donut
                self.donutChartView.segments = [
                    .init(value: CGFloat(pending), color: .systemOrange),
                    .init(value: CGFloat(inProgress), color: .systemBlue),
                    .init(value: CGFloat(completed), color: .systemGreen)
                ]
            }
        }
    }
}
