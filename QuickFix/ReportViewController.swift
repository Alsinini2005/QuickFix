import UIKit
import FirebaseFirestore

final class ReportViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    struct ReportSummary {
        let docId: String
        let type: String               // "monthly" / "yearly"
        let createdAt: Date
        let periodStart: Date
        let periodEnd: Date
        let assigned: Int
        let completed: Int

        init?(doc: QueryDocumentSnapshot) {
            let d = doc.data()

            guard
                let type = d["type"] as? String,
                let startTS = d["periodStart"] as? Timestamp,
                let endTS = d["periodEnd"] as? Timestamp
            else { return nil }

            self.docId = doc.documentID
            self.type = type
            self.periodStart = startTS.dateValue()
            self.periodEnd = endTS.dateValue()

            // createdAt may be missing in older docs, so fallback to now (won't crash)
            self.createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            let totals = d["totals"] as? [String: Any] ?? [:]
            self.assigned = totals["assigned"] as? Int ?? 0
            self.completed = (totals["completed"] as? Int) ?? (totals["resolved"] as? Int ?? 0)
        }
    }

    private var monthlyReports: [ReportSummary] = []
    private var yearlyReports: [ReportSummary] = []

    // createdAt title formatter (you asked for this)
    private lazy var createdAtFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, h:mm a"
        return f
    }()

    private lazy var rangeFormatter: DateIntervalFormatter = {
        let f = DateIntervalFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        startListening()
    }

    deinit { listener?.remove() }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 16
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        tableView.dataSource = self
        tableView.delegate = self

        // IMPORTANT:
        // Don't register UITableViewCell.self with "ReportCell" because it forces .default style
        // which makes detailTextLabel nil.
        navigationItem.title = "Tech report record"
    }

    private func startListening() {
        listener?.remove()

        listener = db.collection("adminReports")
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("❌ Report list listen error:", error)
                    return
                }

                let docs = snapshot?.documents ?? []
                let all = docs.compactMap { ReportSummary(doc: $0) }

                self.monthlyReports = all.filter { $0.type == "monthly" }
                self.yearlyReports = all.filter { $0.type == "yearly" }

                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }

    // ✅ TITLE = createdAt
    private func reportTitle(_ r: ReportSummary) -> String {
        return createdAtFormatter.string(from: r.createdAt)
    }

    // subtitle shows type + period + stats
    private func reportSubtitle(_ r: ReportSummary) -> String {
        let period = rangeFormatter.string(from: r.periodStart, to: r.periodEnd)
        let typeText = (r.type == "yearly") ? "Yearly" : "Monthly"
        return "\(typeText) • \(period) • Assigned: \(r.assigned) • Done: \(r.completed)"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Since your docs don’t have reportId reliably, pass docId instead.
        guard let payload = sender as? (docId: String, type: String) else { return }

        // if your destination supports docId, this is best
        segue.destination.setValue(payload.docId, forKey: "docId")
        segue.destination.setValue(payload.type, forKey: "type")
    }
}

// MARK: - Table Data Source
extension ReportViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? monthlyReports.count : yearlyReports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // ✅ Use .subtitle so detailTextLabel exists
        let reuse = "ReportCellSubtitle"
        let cell = tableView.dequeueReusableCell(withIdentifier: reuse)
            ?? UITableViewCell(style: .subtitle, reuseIdentifier: reuse)

        cell.selectionStyle = .default
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .white

        let item = (indexPath.section == 0)
        ? monthlyReports[indexPath.row]
        : yearlyReports[indexPath.row]

        cell.textLabel?.text = reportTitle(item)
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.textColor = .label
        cell.textLabel?.numberOfLines = 1

        cell.detailTextLabel?.text = reportSubtitle(item)
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.detailTextLabel?.numberOfLines = 2

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - Table Delegate
extension ReportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 86 }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.systemGray5.cgColor
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = (section == 0) ? "Monthly Report" : "Yearly Report"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label

        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat { 48 }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = (indexPath.section == 0)
        ? monthlyReports[indexPath.row]
        : yearlyReports[indexPath.row]

        if item.type == "monthly" {
            performSegue(withIdentifier: "ShowMonthlyReport", sender: (docId: item.docId, type: "monthly"))
        } else {
            performSegue(withIdentifier: "ShowYearlyReport", sender: (docId: item.docId, type: "yearly"))
        }
    }
}
