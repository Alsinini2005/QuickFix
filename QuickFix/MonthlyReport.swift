//
//  MonthlyReport.swift
//  QuickFix
//
//  Created by BP-36-212-01 on 24/12/2025.
//



import UIKit
import FirebaseFirestore

final class MonthlyReportListViewController: UIViewController {

    // MARK: - Outlet (connect in storyboard)
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var reports: [AdminReportRow] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        startListening()
    }

    deinit { listener?.remove() }

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

        var content = cell.defaultContentConfiguration()
        content.text = "Monthly Report: \(r.periodStartText) → \(r.periodEndText)"
        content.secondaryText = "Assigned: \(r.assigned) • Resolved: \(r.resolved)"
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MonthlyReportListViewController: UITableViewDelegate {

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

