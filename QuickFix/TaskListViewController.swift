import UIKit
import FirebaseFirestore

// MARK: - Model
struct TaskRow {
    let id: String
    let title: String
    let location: String
    let status: String
    let submittedAt: Date
}

final class TaskListViewController: UIViewController {

    // MARK: - UI
    private let tableView = UITableView(frame: .zero, style: .plain)

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var tasks: [TaskRow] = []
    private var selectedTaskId: String?

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Tasks"
        view.backgroundColor = .systemBackground

        setupTable()
        startListening()
    }

    deinit { listener?.remove() }

    // MARK: - Table setup
    private func setupTable() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        tableView.separatorStyle = .none
        tableView.backgroundColor = .systemGroupedBackground
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)

        tableView.register(TaskCardCell.self, forCellReuseIdentifier: TaskCardCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Firestore
    private func startListening() {
        listener?.remove()

        listener = db.collection("StudentRepairRequests")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    print("❌ Task list error:", err.localizedDescription)
                    return
                }

                self.tasks = snap?.documents.map { doc in
                    let d = doc.data()

                    let title = (d["ticketName"] as? String)
                        ?? (d["problemTitle"] as? String)
                        ?? "Untitled Task"

                    let campus = (d["campus"] as? String) ?? ""
                    let building = (d["building"] as? String) ?? ""
                    let room = (d["classroom"] as? String) ?? ""

                    let location = [campus, building, room]
                        .filter { !$0.isEmpty }
                        .joined(separator: " • ")

                    let status = (d["status"] as? String) ?? "pending"
                    let submittedAt =
                        (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                    return TaskRow(
                        id: doc.documentID,
                        title: title,
                        location: location.isEmpty ? "No location" : location,
                        status: status,
                        submittedAt: submittedAt
                    )
                } ?? []

                self.tableView.reloadData()
            }
    }

    // MARK: - Segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if segue.identifier == "showTaskDetails",
           let vc = segue.destination as? TicketDetailsViewController {
            vc.requestId = selectedTaskId
        }
    }
}

// MARK: - Table DataSource & Delegate
extension TaskListViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: TaskCardCell.reuseId,
            for: indexPath
        ) as! TaskCardCell

        cell.configure(with: tasks[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        selectedTaskId = tasks[indexPath.row].id
        performSegue(withIdentifier: "showTaskDetails", sender: self)
    }
}

// MARK: - Custom Cell
final class TaskCardCell: UITableViewCell {

    static let reuseId = "TaskCardCell"

    private let card = UIView()
    private let titleLabel = UILabel()
    private let locationLabel = UILabel()
    private let dateLabel = UILabel()
    private let statusLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        card.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(card)

        card.backgroundColor = .secondarySystemGroupedBackground
        card.layer.cornerRadius = 16
        card.layer.shadowOpacity = 0.06
        card.layer.shadowRadius = 8
        card.layer.shadowOffset = CGSize(width: 0, height: 6)

        NSLayoutConstraint.activate([
            card.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            card.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            card.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16)
        ])

        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.numberOfLines = 2

        locationLabel.font = .systemFont(ofSize: 14)
        locationLabel.textColor = .secondaryLabel

        dateLabel.font = .systemFont(ofSize: 13)
        dateLabel.textColor = .secondaryLabel

        statusLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        statusLabel.textColor = .white
        statusLabel.layer.cornerRadius = 10
        statusLabel.layer.masksToBounds = true
        statusLabel.textAlignment = .center

        let topRow = UIStackView(arrangedSubviews: [titleLabel, statusLabel])
        topRow.axis = .horizontal
        topRow.spacing = 10

        statusLabel.setContentHuggingPriority(.required, for: .horizontal)

        let stack = UIStackView(arrangedSubviews: [topRow, locationLabel, dateLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14),
            statusLabel.heightAnchor.constraint(equalToConstant: 22),
            statusLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 86)
        ])
    }

    func configure(with task: TaskRow) {
        titleLabel.text = task.title
        locationLabel.text = task.location

        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        dateLabel.text = "Submitted: \(df.string(from: task.submittedAt))"

        switch task.status.lowercased() {
        case "completed":
            statusLabel.text = "  Completed  "
            statusLabel.backgroundColor = .systemGreen
        case "in_progress":
            statusLabel.text = "  In Progress  "
            statusLabel.backgroundColor = .systemOrange
        default:
            statusLabel.text = "  Pending  "
            statusLabel.backgroundColor = .systemRed
        }
    }
}
