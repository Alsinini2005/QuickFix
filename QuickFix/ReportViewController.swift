import UIKit

final class ReportViewController: UIViewController {

    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var month: Int = 1
    var year: Int = 2025

    fileprivate var results: [UsedItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Monthly Report"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.rowHeight = 64

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadReport),
                                               name: .usageDidChange,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadReport()
    }

    @objc private func reloadReport() {
        results = DataStore.shared.monthlyUsedSummary(month: month, year: year)

        let totalQty = results.reduce(0) { $0 + $1.qty }
        summaryLabel.text = "Month: \(month)/\(year)\nTotal Items: \(results.count)\nTotal Quantity: \(totalQty)"

        tableView.reloadData()
    }
}

extension ReportViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reportCell")
        let item = results[indexPath.row]

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "Part: \(item.partNumber) | Used Qty: \(item.qty)"
        cell.selectionStyle = .none
        return cell
    }
}


