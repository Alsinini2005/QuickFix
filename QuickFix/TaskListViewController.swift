import UIKit
import FirebaseFirestore

// MARK: - Storyboard Cell
final class InfoCell: UITableViewCell {

    @IBOutlet weak var titleLeftLabel: UILabel!
    @IBOutlet weak var titleRightLabel: UILabel!

    @IBOutlet weak var submittedLeftLabel: UILabel!
    @IBOutlet weak var submittedRightLabel: UILabel!

    @IBOutlet weak var statusLeftLabel: UILabel!
    @IBOutlet weak var statusRightLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        selectionStyle = .none

        titleLeftLabel.text = "Problem:"
        submittedLeftLabel.text = "Submitted:"
        statusLeftLabel.text = "Status:"

        titleLeftLabel.textColor = .secondaryLabel
        submittedLeftLabel.textColor = .secondaryLabel
        statusLeftLabel.textColor = .secondaryLabel

        titleRightLabel.numberOfLines = 0
        titleRightLabel.lineBreakMode = .byWordWrapping
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleRightLabel.text = nil
        submittedRightLabel.text = nil
        statusRightLabel.text = nil
    }

    func configure(problem: String, submitted: String, status: String) {
        titleRightLabel.text = problem
        submittedRightLabel.text = submitted
        statusRightLabel.text = status
    }
}

// MARK: - Task List
final class TaskListViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private struct Row {
        let id: String
        let problemDescription: String
        let createdAt: Date
        let status: String
    }

    private var rows: [Row] = []

    private lazy var df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy h:mm a"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Task List"
        setupTable()
        startListening()
    }

    deinit { listener?.remove() }

    private func setupTable() {
        if tableView == nil {
            print("❌ tableView outlet NOT connected")
            return
        }

        tableView.dataSource = self
        tableView.delegate = self

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)
    }

    private func startListening() {
        listener?.remove()

        listener = db.collection("StudentRepairRequests")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err = err {
                    print("❌ Firestore error:", err.localizedDescription)
                    return
                }

                let docs = snap?.documents ?? []

                self.rows = docs.map { doc in
                    let d = doc.data()
                    return Row(
                        id: doc.documentID,
                        problemDescription: (d["problemDescription"] as? String) ?? "(no description)",
                        createdAt: (d["createdAt"] as? Timestamp)?.dateValue() ?? Date(timeIntervalSince1970: 0),
                        status: (d["status"] as? String) ?? "pending"
                    )
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func prettyStatus(_ s: String) -> String {
        switch s.lowercased() {
        case "pending": return "Pending"
        case "in_progress", "in progress": return "In Progress"
        case "completed": return "Completed"
        default: return s
        }
    }

    // ✅ Option A: storyboard segue (cell -> details). We only pass requestId here.
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let dest = segue.destination as? TicketDetailsViewController else { return }
        guard let indexPath = tableView.indexPathForSelectedRow else { return }
        dest.requestId = rows[indexPath.row].id
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "InfoCell",
            for: indexPath
        ) as? InfoCell else {
            return UITableViewCell()
        }

        let r = rows[indexPath.row]
        let submitted = (r.createdAt.timeIntervalSince1970 == 0)
            ? "-"
            : df.string(from: r.createdAt)

        cell.configure(
            problem: r.problemDescription,
            submitted: submitted,
            status: prettyStatus(r.status)
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {

    // ✅ Option A: do NOT call performSegue here. storyboard handles navigation.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        12
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
