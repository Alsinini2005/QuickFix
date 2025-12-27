import UIKit
import FirebaseFirestore

final class MonthlyReportListViewController: UIViewController {

    // MARK: - Outlet (connect in storyboard)
   

    @IBOutlet var tableView: UITableView!
    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var reports: [AdminReportRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = self
        tableView.delegate = self

        setupNavBar()
        setupTableUI()

        startListening()
    }

    deinit { listener?.remove() }
    
    // MARK: - UI

    private func setupNavBar() {
        title = "Technician Performance"   // change if you want

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
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)
    }

    private func applyCardStyle(to cell: UITableViewCell) {
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        cell.contentView.backgroundColor = UIColor(white: 0.95, alpha: 1) // light gray card
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.masksToBounds = true

        // remove any border/shadow
        cell.contentView.layer.borderWidth = 0
        cell.contentView.layer.borderColor = nil
        cell.contentView.layer.shadowOpacity = 0
        cell.contentView.layer.shadowColor = nil
    }

    // MARK: - Firebase listen

    private func startListening() {
        listener?.remove()

        listener = db.collection("adminReports")
            .whereField("type", isEqualTo: "monthly")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Monthly reports listen error:", error)
                    return
                }

                guard let snapshot else {
                    self.reports = []
                    DispatchQueue.main.async { self.tableView.reloadData() }
                    return
                }

                self.reports = snapshot.documents.compactMap { AdminReportRow.from(doc: $0) }
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }
}

// MARK: - UITableViewDataSource
extension MonthlyReportListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath)
        let r = reports[indexPath.row]

        applyCardStyle(to: cell)

        // Remove old custom views (reuse safe)
        cell.contentView.viewWithTag(1001)?.removeFromSuperview()
        cell.contentView.viewWithTag(1002)?.removeFromSuperview()

        // Top label (small)
        let nameLabel = UILabel()
        nameLabel.tag = 1001
        nameLabel.text = "Monthly Report"
        nameLabel.textColor = .label
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.numberOfLines = 1

        // Big number (choose what you want to show)
        // Change to r.assigned if you want assigned instead
        let bigNumberLabel = UILabel()
        bigNumberLabel.tag = 1002
        bigNumberLabel.text = "\(r.resolved)"
        bigNumberLabel.textColor = .label
        bigNumberLabel.font = .systemFont(ofSize: 20, weight: .bold)

        cell.contentView.addSubview(nameLabel)
        cell.contentView.addSubview(bigNumberLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        bigNumberLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 14),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16),

            bigNumberLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            bigNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),
            bigNumberLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -14),
            bigNumberLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16)
        ])

        cell.accessoryType = .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MonthlyReportListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        86
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        // spacing around the card
        let horizontal: CGFloat = 16
        let vertical: CGFloat = 8
        let frame = cell.contentView.frame
        cell.contentView.frame = frame.inset(by: UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let r = reports[indexPath.row]
        let message = "Period:\n\(r.periodStartText) → \(r.periodEndText)\n\nAssigned: \(r.assigned)\nResolved: \(r.resolved)"

        let a = UIAlertController(title: "Monthly Report", message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Model
private struct AdminReportRow {
    let id: String
    let periodStart: Date
    let periodEnd: Date
    let assigned: Int
    let resolved: Int

    var periodStartText: String { periodStart.formatted(date: .abbreviated, time: .omitted) }
    var periodEndText: String { periodEnd.formatted(date: .abbreviated, time: .omitted) }

    static func from(doc: QueryDocumentSnapshot) -> AdminReportRow? {
        let data = doc.data()

        guard let startTS = data["periodStart"] as? Timestamp,
              let endTS = data["periodEnd"] as? Timestamp else { return nil }

        let totals = data["totals"] as? [String: Any]
        let assigned = totals?["assigned"] as? Int ?? 0
        let resolved = totals?["resolved"] as? Int ?? 0

        return AdminReportRow(
            id: doc.documentID,
            periodStart: startTS.dateValue(),
            periodEnd: endTS.dateValue(),
            assigned: assigned,
            resolved: resolved
        )
    }
}
