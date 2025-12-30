import UIKit

final class YearlyReportViewController: UIViewController {

    // passed from ReportViewController
    var report: ReportItem!

    // connect in storyboard
    @IBOutlet private weak var textView: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Yearly Report"
        view.backgroundColor = .systemBackground

        textView.isEditable = false
        render()
    }

    private func render() {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short

        let assigned = report.totals["assigned"] ?? 0
        let completed = report.totals["completed"] ?? 0

        let techLines: [String] = report.byTechnician
            .sorted(by: { $0.key < $1.key })
            .map { "\($0.key): \($0.value)" }

        let techText = techLines.isEmpty ? "No technician data." : techLines.joined(separator: "\n")

        textView.text =
        """
        Type: \(report.type)
        Created By: \(report.createdBy)
        Created At: \(df.string(from: report.createdAt))

        Period:
        \(df.string(from: report.periodStart)) → \(df.string(from: report.periodEnd))

        Totals:
        Assigned: \(assigned)
        Completed: \(completed)

        By Technician:
        \(techText)
        """
    }
}
