import UIKit
import FirebaseFirestore

// MARK: - Model
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

// MARK: - ViewController
final class TechnicianTasksViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var acceptButton: UIButton!
    @IBOutlet private weak var rejectButton: UIButton!

    private var tasks: [TaskItem] = []
    private var selectedTaskIDs = Set<String>()

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        updateButtonsState()
        startListening()
    }

    deinit {
        listener?.remove()
    }

    private func startListening() {
        listener?.remove()

        listener = db.collection("tasks")
            .addSnapshotListener { [weak self] snapshot, error in

                if let error = error {
                    print("❌ Firestore error:", error.localizedDescription)
                    return
                }

                let count = snapshot?.documents.count ?? 0
                print("✅ got tasks:", count)

                guard let self else { return }

                let docs = snapshot?.documents ?? []
                self.tasks = docs.compactMap { TaskItem(doc: $0) }

                print("✅ parsed tasks:", self.tasks.count)

                self.tableView.reloadData()
            }
    }

    // MARK: - Actions
    @IBAction private func acceptPressed(_ sender: UIButton) {
        guard !selectedTaskIDs.isEmpty else {
            showInfoAlert(title: "No Selection", message: "Please select at least one task.")
            return
        }

        updateSelectedTasksStatus(to: "accepted") { [weak self] in
            self?.showInfoAlert(title: "Done", message: "Selected task(s) accepted ✅")
        }
    }

    @IBAction private func rejectPressed(_ sender: UIButton) {
        guard !selectedTaskIDs.isEmpty else {
            showInfoAlert(title: "No Selection", message: "Please select at least one task.")
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
            self?.updateSelectedTasksStatus(to: "rejected", extra: ["rejectReason": reason]) {
                self?.showInfoAlert(title: "Done", message: "Selected task(s) rejected ❌")
            }
        })

        present(alert, animated: true)
    }

    // MARK: - Helpers
    private func updateSelectedTasksStatus(
        to newStatus: String,
        extra: [String: Any] = [:],
        completion: (() -> Void)? = nil
    ) {
        let ids = Array(selectedTaskIDs)
        guard !ids.isEmpty else { return }

        let group = DispatchGroup()

        for id in ids {
            group.enter()

            var data: [String: Any] = ["status": newStatus]
            extra.forEach { data[$0.key] = $0.value }

            db.collection("tasks").document(id).updateData(data) { _ in
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.selectedTaskIDs.removeAll()
            self?.updateButtonsState()
            completion?()
        }
    }

    private func updateButtonsState() {
        let enabled = !selectedTaskIDs.isEmpty
        acceptButton.isEnabled = enabled
        rejectButton.isEnabled = enabled
        acceptButton.alpha = enabled ? 1.0 : 0.5
        rejectButton.alpha = enabled ? 1.0 : 0.5
    }

    private func showInfoAlert(title: String, message: String) {
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
        cell.detailTextLabel?.text = "\(task.details) • \(task.status)"

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

