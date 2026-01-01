//
//  TasksViewController.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit
import FirebaseFirestore

final class TasksViewController: UIViewController {
    @IBOutlet private weak var acceptedTableView: UITableView!
        @IBOutlet private weak var pendingTableView: UITableView!

        private let db = Firestore.firestore()
        private var acceptedListener: ListenerRegistration?
        private var pendingListener: ListenerRegistration?

        private struct TaskItem {
            let docId: String
            let name: String
            let number: String
            let imageUrl: String?
            let status: String
        }

        private var acceptedTasks: [TaskItem] = []
        private var pendingTasks: [TaskItem] = []

        override func viewDidLoad() {
            super.viewDidLoad()

            acceptedTableView.dataSource = self
            acceptedTableView.delegate = self

            pendingTableView.dataSource = self
            pendingTableView.delegate = self

            startListening()
        }

        deinit {
            acceptedListener?.remove()
            pendingListener?.remove()
        }

        private func startListening() {
            // Accepted
            acceptedListener = db.collection("tasks")
                .whereField("status", isEqualTo: "accepted")
                .addSnapshotListener { [weak self] snap, err in
                    guard let self else { return }
                    if let err { print("accepted err:", err); return }
                    let docs = snap?.documents ?? []
                    self.acceptedTasks = docs.map { d in
                        let data = d.data()
                        return TaskItem(
                            docId: d.documentID,
                            name: (data["taskName"] as? String) ?? "Task",
                            number: (data["taskNumber"] as? String) ?? "-",
                            imageUrl: (data["imageUrl"] as? String),
                            status: (data["status"] as? String) ?? "accepted"
                        )
                    }
                    self.acceptedTableView.reloadData()
                }

            // Pending
            pendingListener = db.collection("tasks")
                .whereField("status", isEqualTo: "pending")
                .addSnapshotListener { [weak self] snap, err in
                    guard let self else { return }
                    if let err { print("pending err:", err); return }
                    let docs = snap?.documents ?? []
                    self.pendingTasks = docs.map { d in
                        let data = d.data()
                        return TaskItem(
                            docId: d.documentID,
                            name: (data["taskName"] as? String) ?? "Task",
                            number: (data["taskNumber"] as? String) ?? "-",
                            imageUrl: (data["imageUrl"] as? String),
                            status: (data["status"] as? String) ?? "pending"
                        )
                    }
                    self.pendingTableView.reloadData()
                }
        }

        private func item(for tableView: UITableView, at indexPath: IndexPath) -> TaskItem {
            if tableView == acceptedTableView { return acceptedTasks[indexPath.row] }
            return pendingTasks[indexPath.row]
        }

        // Segue to edit/details
        override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
            guard segue.identifier == "toTaskEdit",
                  let payload = sender as? TaskItem else { return }

            // change this to your real edit VC class
            if let vc = segue.destination as? TaskEditViewController {
                vc.taskId = payload.docId
                vc.currentStatus = payload.status
            }
        }
    }

    // MARK: - UITableViewDataSource + UITableViewDelegate
    extension TasksSplitViewController: UITableViewDataSource, UITableViewDelegate {

        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            if tableView == acceptedTableView { return acceptedTasks.count }
            return pendingTasks.count
        }

        func tableView(_ tableView: UITableView,
                       cellForRowAt indexPath: IndexPath) -> UITableViewCell {

            guard let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell",
                                                           for: indexPath) as? TaskCell else {
                return UITableViewCell()
            }

            let t = item(for: tableView, at: indexPath)
            cell.configure(name: t.name, number: t.number, imageURL: t.imageUrl)
            cell.accessoryType = .disclosureIndicator
            return cell
        }

        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let t = item(for: tableView, at: indexPath)
            performSegue(withIdentifier: "toTaskEdit", sender: t)
        }
}
