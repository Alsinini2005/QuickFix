import UIKit
import FirebaseFirestore

final class ReportViewController: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Firestore
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var reports: [ReportItem] = []

    // MARK: - Storyboard segues (set these identifiers in storyboard)
    private let segueToMonthly = "toMonthlyReport"
    private let segueToYearly  = "toYearlyReport"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Reports"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")

        listenReports()
    }

    deinit { listener?.remove() }

    // MARK: - Firestore
    private func listenReports() {
        listener?.remove()

        let ref = db.collection("reports") // ✅ make sure this matches your Firebase collection name exactly

        // 1) Try with orderBy first
        listener = ref
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snap, err in
                guard let self = self else { return }

                if let err = err {
                    print("❌ Firestore listenReports error (orderBy):", err.localizedDescription)
                    self.showAlert(title: "Reports Error", message: err.localizedDescription)

                    // 2) Fallback: try without orderBy (in case createdAt missing / index issue)
                    self.listener?.remove()
                    self.listener = ref.addSnapshotListener { [weak self] snap2, err2 in
                        guard let self = self else { return }

                        if let err2 = err2 {
                            print("❌ Firestore listenReports error (no orderBy):", err2.localizedDescription)
                            self.showAlert(title: "Reports Error", message: err2.localizedDescription)
                            return
                        }

                        let docs2 = snap2?.documents ?? []
                        print("✅ reports docs (no orderBy):", docs2.count)

                        self.reports = docs2.compactMap { ReportItem(doc: $0) }
                        print("✅ parsed reports:", self.reports.count)

                        DispatchQueue.main.async { self.tableView.reloadData() }
                    }

                    return
                }

                let docs = snap?.documents ?? []
                print("✅ reports docs (orderBy):", docs.count)

                self.reports = docs.compactMap { ReportItem(doc: $0) }
                print("✅ parsed reports:", self.reports.count)

                DispatchQueue.main.async { self.tableView.reloadData() }
            }
        print("cellForRowAt called, reports count:", reports.count)

    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let report = sender as? ReportItem else { return }

        if segue.identifier == segueToMonthly,
           let vc = segue.destination as? MonthlyReportViewController {
            vc.report = report
        }

        if segue.identifier == segueToYearly,
           let vc = segue.destination as? YearlyReportViewController {
            vc.report = report
        }
    }

    // MARK: - Helpers
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.async {
            let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(a, animated: true)
        }
    }

    private func dateText(_ date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df.string(from: date)
    }
}

// MARK: - UITableViewDataSource
extension ReportViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        reports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath)
        let r = reports[indexPath.row]

        let assigned = r.totals["assigned"] ?? 0
        let completed = r.totals["completed"] ?? 0

        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.text =
        """
        \(r.type.capitalized) Report
        Period: \(dateText(r.periodStart)) → \(dateText(r.periodEnd))
        Totals: assigned \(assigned), completed \(completed)
        Created by: \(r.createdBy)
        """

        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let report = reports[indexPath.row]
        let type = report.type.lowercased()

        if type == "monthly" {
            performSegue(withIdentifier: segueToMonthly, sender: report)
        } else {
            // treat anything else as yearly (matches your data "yearly")
            performSegue(withIdentifier: segueToYearly, sender: report)
        }
    }
}
