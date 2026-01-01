import UIKit
import FirebaseFirestore

final class TechnicianTasksViewController: UIViewController {

    // MARK: - Model (local)
    struct TaskItem {
        let id: String
        let title: String
        let details: String
        let status: String

        init?(doc: DocumentSnapshot) {
            let data = doc.data() ?? [:]

            guard
                let title = data["title"] as? String,
                let details = data["details"] as? String,
                let status = data["status"] as? String
            else { return nil }

            self.id = doc.documentID
            self.title = title
            self.details = details
            self.status = status
        }
    }

    // MARK: - Outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var acceptButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var tasks: [TaskItem] = []
    private var selectedTaskIDs = Set<String>()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Assign Task"

        tableView.dataSource = self
        tableView.delegate = self

        updateButtonsState()
        startListeningAssignedTasks()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Firestore
    private func startListeningAssignedTasks() {
        listener?.remove()

        listener = db.collection("AssTasks")
            .whereField("status", isEqualTo: "assigned")
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("Firestore error:", error.localizedDescription)
                    return
                }

                guard let self else { return }

                let docs = snapshot?.documents ?? []
                self.tasks = docs.compactMap { TaskItem(doc: $0) }

                self.tableView.reloadData()
            }
    }

    // MARK: - Actions
    @IBAction func acceptPressed(_ sender: UIButton) {
        guard !selectedTaskIDs.isEmpty else {
            showAlert("No Selection", "Select at least one task.")
            return
        }

        updateSelectedTasksStatus(to: "accepted") { [weak self] in
            self?.resetSelection()
            self?.showAlert("Done", "Task accepted.")
        }
    }

    @IBAction func rejectPressed(_ sender: UIButton) {
        guard !selectedTaskIDs.isEmpty else {
            showAlert("No Selection", "Select at least one task.")
            return
        }

        let alert = UIAlertController(
            title: "Reject Task",
            message: "Write a reason (optional):",
            preferredStyle: .alert
        )

        alert.addTextField { $0.placeholder = "Reason..." }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        alert.addAction(UIAlertAction(title: "Submit", style: .destructive) { [weak self] _ in
            let reason = alert.textFields?.first?.text ?? ""

            self?.updateSelectedTasksStatus(
                to: "rejected",
                extra: ["rejectReason": reason]
            ) {
                self?.resetSelection()
                self?.showAlert("Done", "Task rejected.")
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Firestore Update
    private func updateSelectedTasksStatus(
        to newStatus: String,
        extra: [String: Any] = [:],
        completion: (() -> Void)? = nil
    ) {
        let ids = Array(selectedTaskIDs)
        let group = DispatchGroup()

        for id in ids {
            group.enter()

            var data: [String: Any] = [
                "status": newStatus,
                "updatedAt": FieldValue.serverTimestamp()
            ]
            extra.forEach { data[$0.key] = $0.value }

            db.collection("AssTsasks").document(id).updateData(data) { err in
                if let err = err {
                    print("Update error:", err.localizedDescription)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            completion?()
        }
    }

    // MARK: - Helpers
    private func resetSelection() {
        selectedTaskIDs.removeAll()
        updateButtonsState()
    }

    private func updateButtonsState() {
        let enabled = !selectedTaskIDs.isEmpty
        acceptButton.isEnabled = enabled
        rejectButton.isEnabled = enabled
        acceptButton.alpha = enabled ? 1 : 0.5
        rejectButton.alpha = enabled ? 1 : 0.5
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - TableView
extension TechnicianTasksViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell")
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: "TaskCell")

        let task = tasks[indexPath.row]
        cell.textLabel?.text = task.title
        cell.detailTextLabel?.text = task.details
        cell.accessoryType = selectedTaskIDs.contains(task.id) ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let id = tasks[indexPath.row].id
        if selectedTaskIDs.contains(id) {
            selectedTaskIDs.remove(id)
        } else {
            selectedTaskIDs.insert(id)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
        updateButtonsState()
    }
}

