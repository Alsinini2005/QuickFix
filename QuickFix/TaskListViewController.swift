import UIKit
import FirebaseFirestore

// MARK: - Custom Cell (same file so you don't need another swift file)
final class InfoCell: UITableViewCell {

    // Connect these 6 labels from storyboard
    @IBOutlet weak var titleLeftLabel: UILabel!
    @IBOutlet weak var titleRightLabel: UILabel!

    @IBOutlet weak var submittedLeftLabel: UILabel!
    @IBOutlet weak var submittedRightLabel: UILabel!

    @IBOutlet weak var statusLeftLabel: UILabel!
    @IBOutlet weak var statusRightLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()

        selectionStyle = .none

        // Fixed left titles
        titleLeftLabel.text = "Ticket Title:"
        submittedLeftLabel.text = "Submitted:"
        statusLeftLabel.text = "Status:"

        // Basic styling (optional)
        titleLeftLabel.textColor = .secondaryLabel
        submittedLeftLabel.textColor = .secondaryLabel
        statusLeftLabel.textColor = .secondaryLabel

        titleRightLabel.textColor = .label
        submittedRightLabel.textColor = .label
        statusRightLabel.textColor = .label

        titleRightLabel.numberOfLines = 0
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        titleRightLabel.text = nil
        submittedRightLabel.text = nil
        statusRightLabel.text = nil
    }

    func configure(title: String, submitted: String, status: String) {
        titleRightLabel.text = title
        submittedRightLabel.text = submitted
        statusRightLabel.text = status
    }
}

// MARK: - Task List VC
final class TaskListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // Firestore
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // Data model
    struct Ticket {
        let id: String
        let title: String
        let createdAt: Date
        let status: String

        init?(doc: QueryDocumentSnapshot) {
            let data = doc.data()
            guard let title = data["title"] as? String else { return nil }

            self.id = doc.documentID
            self.title = title
            self.status = (data["status"] as? String) ?? "pending"
            self.createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        }
    }

    private var tickets: [Ticket] = []

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTable()
        startListening()
    }

    deinit { listener?.remove() }

    // MARK: - UI
    private func setupNavBar() {
        title = "Task List"

        let barColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barColor
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupTable() {
        view.backgroundColor = .systemGroupedBackground

        tableView.dataSource = self
        tableView.delegate = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)

        // Auto height (best with custom cell + stack views)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 140
    }

    // MARK: - Firestore
    private func startListening() {
        listener?.remove()

        listener = db.collection("requests")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("❌ TaskList listen error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.tickets = docs.compactMap { Ticket(doc: $0) }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    private func prettyStatus(_ status: String) -> String {
        switch status {
        case "pending": return "Pending"
        case "in_progress": return "In Progress"
        case "completed": return "Completed"
        default: return status
        }
    }

    // MARK: - Segue to details (PASS requestId)
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowTicketDetails",
           let vc = segue.destination as? TicketDetailsViewController,
           let indexPath = sender as? IndexPath {

            vc.requestId = tickets[indexPath.row].id
        }
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tickets.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(withIdentifier: "InfoCell",
                                                       for: indexPath) as? InfoCell else {
            return UITableViewCell()
        }

        let t = tickets[indexPath.row]
        let submittedText = dateFormatter.string(from: t.createdAt)

        cell.configure(
            title: t.title,
            submitted: submittedText,
            status: prettyStatus(t.status)
        )

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // Tap opens Ticket Details
        performSegue(withIdentifier: "ShowTicketDetails", sender: indexPath)
    }

    // spacing between cells
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        12
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let v = UIView()
        v.backgroundColor = .clear
        return v
    }
}
