import UIKit

final class ReportViewController: UIViewController {

    @IBOutlet weak var summaryTitleLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var items: [ViewController.ReportItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Inventory Report"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.rowHeight = 64

        summaryTitleLabel.text = "Summary"

        let totalParts = items.count
        let totalQty = items.reduce(0) { $0 + $1.quantity }
        summaryLabel.text = "Total Parts: \(totalParts)\nTotal Quantity: \(totalQty)"
    }
}

extension ReportViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "reportCell")
        let item = items[indexPath.row]

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "Part: \(item.partNumber) | Qty: \(item.quantity)"
        cell.selectionStyle = .none
        return cell
    }
}

