import UIKit
import FirebaseFirestore

final class SchedualOverViewTech: UIViewController {

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

    // MARK: - Properties
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var tasks: [TaskItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Schedule Overview"

        tableView.dataSource = self
        tableView.delegate = self

        startListeningAcceptedTasks()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Firestore
    private func startListeningAcceptedTasks() {
        listener?.remove()

        listener = db.collection("AssTasks")
            .whereField("status", isEqualTo: "accepted")
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
}

// MARK: - TableView
extension SchedualOverViewTech: UITableViewDataSource, UITableViewDelegate {

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

        return cell
    }
}

