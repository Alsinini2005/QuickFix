import UIKit
import FirebaseAuth
import FirebaseFirestore

// MARK: - Model + Status

private enum RequestStatus: String {
    case pending = "pending"
    case inProgress = "in_progress"
    case completed = "completed"

    var title: String {
        switch self {
        case .pending: return "Pending"
        case .inProgress: return "In Progress"
        case .completed: return "Completed"
        }
    }

    var dotColor: UIColor {
        switch self {
        case .pending: return UIColor(red: 241/255, green: 90/255, blue: 90/255, alpha: 1)
        case .inProgress: return UIColor(red: 225/255, green: 169/255, blue: 40/255, alpha: 1)
        case .completed: return UIColor(red: 55/255, green: 171/255, blue: 97/255, alpha: 1)
        }
    }

    var badgeBG: UIColor {
        switch self {
        case .pending: return UIColor(red: 1, green: 0.93, blue: 0.93, alpha: 1)
        case .inProgress: return UIColor(red: 1, green: 0.96, blue: 0.86, alpha: 1)
        case .completed: return UIColor(red: 0.88, green: 0.98, blue: 0.91, alpha: 1)
        }
    }

    var badgeText: UIColor { dotColor }
}

private struct RequestRow {
    let id: String
    let title: String
    let createdAt: Date
    let status: RequestStatus

    var createdText: String {
        createdAt.formatted(date: .abbreviated, time: .omitted)
    }

    static func from(doc: QueryDocumentSnapshot) -> RequestRow? {
        let d = doc.data()

        // Firestore fields (based on your StudentRepairRequests collection):
        // title (String), createdAt (Timestamp), status (String)
        guard
            let title = d["title"] as? String,
            let ts = d["createdAt"] as? Timestamp,
            let statusStr = d["status"] as? String,
            let status = RequestStatus(rawValue: statusStr)
        else { return nil }

        return RequestRow(
            id: doc.documentID,
            title: title,
            createdAt: ts.dateValue(),
            status: status
        )
    }
}

// MARK: - ViewController

final class MyRequestsViewController: UIViewController {

    // MARK: - Outlet
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var rows: [RequestRow] = []

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupNavBar()
        setupTableUI()

        tableView.dataSource = self
        tableView.delegate = self

        startListening()
    }

    deinit { listener?.remove() }

    // MARK: - UI

    private func setupNavBar() {
        title = "My Requests"

        let barColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)

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

    private func setupTableUI() {
        view.backgroundColor = .systemGroupedBackground

        tableView.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 14, left: 0, bottom: 20, right: 0)

        // If your cell isn't found (safety)
        if tableView.dequeueReusableCell(withIdentifier: "RequestCell") == nil {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RequestCell")
        }
    }

    // MARK: - Firestore Listener

    private func startListening() {
        listener?.remove()

        guard let authUid = Auth.auth().currentUser?.uid else {
            rows = []
            tableView.reloadData()
            return
        }

        // Your Firebase screenshot shows the collection name is "StudentRepairRequests"
        // and userId is stored as STRING.
        //
        // To be extra-safe with older data, we also match a short id (first 6 chars)
        // in case you previously saved a shortened user id.
        let shortUid = String(authUid.prefix(6))

        listener?.remove()
        listener = db.collection("StudentRepairRequests")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    print("MyRequests listen error:", err)
                    return
                }

                let docs = snap?.documents ?? []

                // Filter to the current user on the client.
                // (Firestore OR queries require extra setup; this is simplest for a student project.)
                let filtered = docs.filter { doc in
                    let d = doc.data()
                    let uidField = d["userId"] as? String
                    return uidField == authUid || uidField == shortUid
                }

                self.rows = filtered.compactMap { RequestRow.from(doc: $0) }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }

    // MARK: - Cell UI

    private func styleCard(_ card: UIView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.masksToBounds = true
    }

    private func styleBadge(_ badge: UIView, dot: UIView) {
        badge.layer.cornerRadius = 10
        badge.layer.masksToBounds = true

        dot.layer.cornerRadius = 3
        dot.layer.masksToBounds = true
    }

    private func showSimpleAlert(_ title: String, _ msg: String) {
        let a = UIAlertController(title: title, message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UITableViewDataSource
extension MyRequestsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Storyboard prototype cell identifier MUST be "RequestCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)
        let row = rows[indexPath.row]

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.accessoryType = .disclosureIndicator

        // reuse-safe cleanup
        let cardTag = 7001
        cell.contentView.viewWithTag(cardTag)?.removeFromSuperview()

        // ----- Card container
        let card = UIView()
        card.tag = cardTag
        styleCard(card)
        cell.contentView.addSubview(card)

        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 10),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -10)
        ])

        // ----- Title
        let titleLabel = UILabel()
        titleLabel.text = row.title
        titleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        // ----- Submitted
        let submittedLabel = UILabel()
        submittedLabel.text = "Submitted: \(row.createdText)"
        submittedLabel.font = .systemFont(ofSize: 12, weight: .regular)
        submittedLabel.textColor = .secondaryLabel
        submittedLabel.translatesAutoresizingMaskIntoConstraints = false

        // ----- Badge
        let badge = UIView()
        badge.backgroundColor = row.status.badgeBG
        badge.translatesAutoresizingMaskIntoConstraints = false

        let dot = UIView()
        dot.backgroundColor = row.status.dotColor
        dot.translatesAutoresizingMaskIntoConstraints = false

        let badgeLabel = UILabel()
        badgeLabel.text = row.status.title
        badgeLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        badgeLabel.textColor = row.status.badgeText
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false

        badge.addSubview(dot)
        badge.addSubview(badgeLabel)

        styleBadge(badge, dot: dot)

        card.addSubview(titleLabel)
        card.addSubview(submittedLabel)
        card.addSubview(badge)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -38),
            titleLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            submittedLabel.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            submittedLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            submittedLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),

            badge.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            badge.topAnchor.constraint(equalTo: submittedLabel.bottomAnchor, constant: 10),
            badge.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -14),

            dot.leadingAnchor.constraint(equalTo: badge.leadingAnchor, constant: 10),
            dot.centerYAnchor.constraint(equalTo: badge.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            badgeLabel.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            badgeLabel.trailingAnchor.constraint(equalTo: badge.trailingAnchor, constant: -10),
            badgeLabel.topAnchor.constraint(equalTo: badge.topAnchor, constant: 4),
            badgeLabel.bottomAnchor.constraint(equalTo: badge.bottomAnchor, constant: -4)
        ])

        return cell
    }
}

// MARK: - UITableViewDelegate
extension MyRequestsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        120
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        // optional
        let r = rows[indexPath.row]
        let msg = "\(r.title)\n\nSubmitted: \(r.createdText)\nStatus: \(r.status.title)"
        showSimpleAlert("Request", msg)
    }
}
