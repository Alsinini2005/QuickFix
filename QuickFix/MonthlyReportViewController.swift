import UIKit
import FirebaseFirestore

// ✅ Add this once in your project (best: in separate file). If already added elsewhere, remove from here.
// protocol AdminReportDocReceivable: AnyObject {
//     var docId: String? { get set }
//     var type: String? { get set }
// }

final class MonthlyReportListViewController: UIViewController, AdminReportDocReceivable {

    // ✅ Will be set from ReportViewController
    var docId: String?
    var type: String?

    @IBOutlet private weak var tableView: UITableView!

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
        title = "Technician Performance"

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
        cell.selectionStyle = .default

        cell.contentView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        cell.contentView.layer.cornerRadius = 10
        cell.contentView.layer.masksToBounds = true

        cell.contentView.layer.borderWidth = 0
        cell.contentView.layer.borderColor = nil
        cell.contentView.layer.shadowOpacity = 0
        cell.contentView.layer.shadowColor = nil
    }

    // MARK: - Firebase listen
    private func startListening() {
        listener?.remove()

        // ✅ If this VC is used as a "list page", load all monthly reports
        // (this is how your UI is built)
        listener = db.collection("adminReports")
            .whereField("type", isEqualTo: "monthly")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Monthly reports listen error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                self.reports = docs.compactMap { AdminReportRow.from(doc: $0) }

                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "ShowMonthlyReportFull",
              let payload = sender as? (docId: String) else { return }

        // ✅ Handle if destination is embedded in nav controller
        let dest: UIViewController
        if let nav = segue.destination as? UINavigationController {
            dest = nav.viewControllers.first ?? nav
        } else {
            dest = segue.destination
        }

        // ✅ Pass docId safely (no KVC crash if you make destination accept it)
        if var receiver = dest as? AdminReportDocReceivable {
            receiver.docId = payload.docId
            receiver.type = "monthly"
        } else {
            // Fallback KVC (only safe if destination has @objc var docId)
            dest.setValue(payload.docId, forKey: "docId")
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
        cell.contentView.viewWithTag(1003)?.removeFromSuperview()

        // Top label
        let nameLabel = UILabel()
        nameLabel.tag = 1001

        // ✅ Use reportId if exists, else fallback to docId short
        if let rid = r.reportId {
            nameLabel.text = "Monthly Report #\(rid)"
        } else {
            nameLabel.text = "Monthly Report • \(r.docId.prefix(6))"
        }

        nameLabel.textColor = .label
        nameLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        nameLabel.numberOfLines = 1

        // Big number = Completed
        let bigNumberLabel = UILabel()
        bigNumberLabel.tag = 1002
        bigNumberLabel.text = "\(r.completed)"
        bigNumberLabel.textColor = .label
        bigNumberLabel.font = .systemFont(ofSize: 22, weight: .bold)

        // Period label
        let periodLabel = UILabel()
        periodLabel.tag = 1003
        periodLabel.text = "\(r.periodStartText) → \(r.periodEndText)"
        periodLabel.textColor = .secondaryLabel
        periodLabel.font = .systemFont(ofSize: 12, weight: .regular)

        cell.contentView.addSubview(nameLabel)
        cell.contentView.addSubview(bigNumberLabel)
        cell.contentView.addSubview(periodLabel)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        bigNumberLabel.translatesAutoresizingMaskIntoConstraints = false
        periodLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            nameLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            nameLabel.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16),

            bigNumberLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            bigNumberLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 6),

            periodLabel.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            periodLabel.topAnchor.constraint(equalTo: bigNumberLabel.bottomAnchor, constant: 2),
            periodLabel.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12),
            periodLabel.trailingAnchor.constraint(lessThanOrEqualTo: cell.contentView.trailingAnchor, constant: -16)
        ])

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MonthlyReportListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        96
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        let horizontal: CGFloat = 16
        let vertical: CGFloat = 8
        let frame = cell.contentView.frame
        cell.contentView.frame = frame.inset(by: UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let r = reports[indexPath.row]
        // ✅ Pass docId (works with your Firestore docs)
        performSegue(withIdentifier: "ShowMonthlyReportFull", sender: (docId: r.docId))
    }
}

// MARK: - Model
private struct AdminReportRow {
    let docId: String
    let reportId: Int?         // ✅ optional now
    let periodStart: Date
    let periodEnd: Date
    let assigned: Int
    let completed: Int

    var periodStartText: String { periodStart.formatted(date: .abbreviated, time: .omitted) }
    var periodEndText: String { periodEnd.formatted(date: .abbreviated, time: .omitted) }

    static func from(doc: QueryDocumentSnapshot) -> AdminReportRow? {
        let data = doc.data()

        guard
            let startTS = data["periodStart"] as? Timestamp,
            let endTS = data["periodEnd"] as? Timestamp
        else { return nil }

        let totals = data["totals"] as? [String: Any] ?? [:]
        let assigned = totals["assigned"] as? Int ?? 0
        let completed = (totals["completed"] as? Int) ?? (totals["resolved"] as? Int ?? 0)

        let reportId = data["reportId"] as? Int

        return AdminReportRow(
            docId: doc.documentID,
            reportId: reportId,
            periodStart: startTS.dateValue(),
            periodEnd: endTS.dateValue(),
            assigned: assigned,
            completed: completed
        )
    }
}
