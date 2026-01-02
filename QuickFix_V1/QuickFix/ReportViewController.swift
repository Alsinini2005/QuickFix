import UIKit
import FirebaseFirestore

/// Admin "Report" list page (tab bar).
/// Shows reports stored in Firestore collection: `adminReports`.
/// Selecting a row pushes a details screen (Monthly / Yearly) based on `type`.
final class ReportViewController: UITableViewController {

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var reports: [ReportItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Report"

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")
        tableView.tableFooterView = UIView()

        listenReports()
    }

    deinit { listener?.remove() }

    // MARK: - Firestore
    private func listenReports() {
        listener?.remove()

        let ref = db.collection("adminReports")

        // Try with orderBy first. If it fails (missing index / field), fallback to no orderBy.
        listener = ref
            .order(by: "createdAt", descending: true)
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    print("❌ adminReports listen error (orderBy createdAt):", err.localizedDescription)
                    self.listenReportsFallback(ref: ref, message: err.localizedDescription)
                    return
                }

                let docs = snap?.documents ?? []
                self.reports = docs.compactMap { ReportItem(doc: $0) }
                DispatchQueue.main.async { self.tableView.reloadData() }
            }
    }

    private func listenReportsFallback(ref: CollectionReference, message: String) {
        listener?.remove()
        listener = ref
            .addSnapshotListener(includeMetadataChanges: true) { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    print("❌ adminReports listen error (no orderBy):", err.localizedDescription)
                    self.showAlert(title: "Reports Error", message: err.localizedDescription)
                    return
                }
                let docs = snap?.documents ?? []
                self.reports = docs.compactMap { ReportItem(doc: $0) }
                DispatchQueue.main.async { self.tableView.reloadData() }
            }

        // Show the original error message once (helps you see if index is required).
        showAlert(title: "Reports Notice", message: "Sorting failed, showing unsorted.\n\n\(message)")
    }

    // MARK: - UITableViewDataSource
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        // Use a subtitle-style cell so the created date appears under the title (user requirement).
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "ReportCell")

        let r = reports[indexPath.row]
        cell.accessoryType = .disclosureIndicator
        cell.textLabel?.numberOfLines = 1
        cell.detailTextLabel?.numberOfLines = 2

        let title = "\(r.type.capitalized) Report"
        cell.textLabel?.text = title

        let createdText = dateTimeText(r.createdAt)
        let periodText = "Period: \(dateText(r.periodStart)) → \(dateText(r.periodEnd))"
        cell.detailTextLabel?.text = "Created: \(createdText)\n\(periodText)"

        return cell
    }

    // MARK: - UITableViewDelegate
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let report = reports[indexPath.row]
        let type = report.type.lowercased()

        if type == "monthly" {
            let vc = MonthlyReportViewController(report: report)
            navigationController?.pushViewController(vc, animated: true)
        } else {
            // treat anything else as yearly (matches your saved value: "yearly")
            let vc = YearlyReportViewController(report: report)
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    // MARK: - Helpers
    private func dateText(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return df.string(from: date)
    }

    private func dateTimeText(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(a, animated: true)
        }
    }
}
