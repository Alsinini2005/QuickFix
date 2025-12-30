import UIKit
import FirebaseFirestore

final class ReportViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    struct ReportSummary {
        let docId: String          // Firestore document id (still useful)
        let reportId: Int          // ✅ numeric id
        let type: String           // "monthly" / "yearly"
        let createdAt: Date
        let periodStart: Date
        let periodEnd: Date
        let assigned: Int
        let completed: Int

        init?(doc: QueryDocumentSnapshot) {
            let d = doc.data()

            guard
                let reportId = d["reportId"] as? Int,
                let type = d["type"] as? String,
                let startTS = d["periodStart"] as? Timestamp,
                let endTS = d["periodEnd"] as? Timestamp
            else { return nil }

            self.docId = doc.documentID
            self.reportId = reportId
            self.type = type
            self.periodStart = startTS.dateValue()
            self.periodEnd = endTS.dateValue()
            self.createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

            let totals = d["totals"] as? [String: Any]
            self.assigned = totals?["assigned"] as? Int ?? 0
            self.completed = (totals?["completed"] as? Int) ?? (totals?["resolved"] as? Int ?? 0)
        }
    }

    private var monthlyReports: [ReportSummary] = []
    private var yearlyReports: [ReportSummary] = []

    private lazy var df: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy"
        return f
    }()

    private lazy var monthFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    private lazy var yearFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy"
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

        if tableView.dequeueReusableCell(withIdentifier: "ReportCell") == nil {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")
        }

        navigationItem.title = "Tech report record"
    }

    private func startListening() {
        listener?.remove()

        // If you want to sort by numeric reportId:
        // make sure you have it in docs and create index if needed.
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

    private func reportTitle(_ r: ReportSummary) -> String {
        if r.type == "monthly" {
            return "#\(r.reportId) • \(monthFormatter.string(from: r.periodStart)) monthly report"
        } else {
            return "#\(r.reportId) • \(yearFormatter.string(from: r.periodStart)) yearly report"
        }
    }

    private func reportSubtitle(_ r: ReportSummary) -> String {
        let created = df.string(from: r.createdAt)
        return "Created: \(created) • Done: \(r.completed)"
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let payload = sender as? (reportId: Int, type: String) else { return }

        // Don’t cast to a specific VC type (prevents “Cannot find type” errors)
        // Just set reportId on destination if it exists.
        if payload.type == "monthly" {
            // ShowMonthlyReport
            if let dest = segue.destination as? (UIViewController & ReportIdReceivable) {
                dest.reportId = payload.reportId
            } else {
                segue.destination.setValue(payload.reportId, forKey: "reportId")
            }
        } else {
            // ShowYearlyReport
            if let dest = segue.destination as? (UIViewController & ReportIdReceivable) {
                dest.reportId = payload.reportId
            } else {
                segue.destination.setValue(payload.reportId, forKey: "reportId")
            }
        }
    }

    }
protocol ReportIdReceivable: AnyObject {
    var reportId: Int! { get set }
}


extension ReportViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? monthlyReports.count : yearlyReports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath)

        cell.selectionStyle = .default
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .white

        let item = (indexPath.section == 0)
        ? monthlyReports[indexPath.row]
        : yearlyReports[indexPath.row]

        cell.textLabel?.text = reportTitle(item)
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.textColor = .label
        cell.textLabel?.numberOfLines = 2

        cell.detailTextLabel?.text = reportSubtitle(item)
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

extension ReportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat { 72 }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.systemGray5.cgColor

        let frame = cell.contentView.frame
        cell.contentView.frame = frame.inset(by: UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16))
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
            performSegue(withIdentifier: "ShowMonthlyReport", sender: (reportId: item.reportId, type: "monthly"))
        } else {
            performSegue(withIdentifier: "ShowYearlyReport", sender: (reportId: item.reportId, type: "yearly"))
        }
    }
}
