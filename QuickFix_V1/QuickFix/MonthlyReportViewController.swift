import UIKit

/// Report details screen for Monthly reports.
/// Built programmatically so it works even if the storyboard scene was set up as a table view.
final class MonthlyReportViewController: UITableViewController {

    private let report: ReportItem

    // MARK: - Init
    init(report: ReportItem) {
        self.report = report
        super.init(style: .insetGrouped)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("Use init(report:) instead")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Monthly Report"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
    }

    // MARK: - Sections
    private enum Section: Int, CaseIterable {
        case summary
        case totals
        case technicians

        var title: String {
            switch self {
            case .summary: return "Summary"
            case .totals: return "Totals"
            case .technicians: return "By Technician"
            }
        }
    }

    // MARK: - UITableViewDataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        Section(rawValue: section)?.title
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let s = Section(rawValue: section) else { return 0 }

        switch s {
        case .summary:
            return 4
        case .totals:
            return 2
        case .technicians:
            return max(report.byTechnician.count, 1)
        }
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.selectionStyle = .none

        guard let s = Section(rawValue: indexPath.section) else { return cell }

        switch s {
        case .summary:
            configureSummaryCell(cell, row: indexPath.row)
        case .totals:
            configureTotalsCell(cell, row: indexPath.row)
        case .technicians:
            configureTechnicianCell(cell, row: indexPath.row)
        }

        return cell
    }

    // MARK: - Cell builders
    private func configureSummaryCell(_ cell: UITableViewCell, row: Int) {
        cell.textLabel?.numberOfLines = 2
        switch row {
        case 0:
            cell.textLabel?.text = "Type: \(report.type.capitalized)"
        case 1:
            cell.textLabel?.text = "Created by: \(report.createdBy)"
        case 2:
            cell.textLabel?.text = "Created at: \(dateTimeText(report.createdAt))"
        default:
            cell.textLabel?.text = "Period: \(dateText(report.periodStart)) → \(dateText(report.periodEnd))"
        }
    }

    private func configureTotalsCell(_ cell: UITableViewCell, row: Int) {
        let assigned = report.totals["assigned"] ?? 0
        let completed = report.totals["completed"] ?? 0
        cell.textLabel?.numberOfLines = 1
        cell.textLabel?.text = (row == 0) ? "Assigned: \(assigned)" : "Completed: \(completed)"
    }

    private func configureTechnicianCell(_ cell: UITableViewCell, row: Int) {
        cell.textLabel?.numberOfLines = 2

        if report.byTechnician.isEmpty {
            cell.textLabel?.text = "No technician data."
            return
        }

        let items = report.byTechnician
            .sorted(by: { $0.key.localizedStandardCompare($1.key) == .orderedAscending })

        let (techId, totals) = items[row]
        cell.textLabel?.text = "\(techId)\nAssigned: \(totals.assigned) • Completed: \(totals.completed)"
    }

    // MARK: - Formatting
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
}
