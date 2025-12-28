import UIKit
import FirebaseFirestore

final class ReportViewController: UIViewController {

    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    var month: Int = 1
    var year: Int = 2025

    private let db = Firestore.firestore()
    private var results: [UsedItem] = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Monthly Report"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.rowHeight = 64
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadReport()
    }

    private func reloadReport() {
        db.collection("usageLogs")
            .whereField("month", isEqualTo: month)
            .whereField("year", isEqualTo: year)
            .getDocuments { [weak self] snap, err in
                guard let self else { return }

                if let err = err {
                    self.summaryLabel.text = "Error: \(err.localizedDescription)"
                    print("Report fetch error:", err)
                    return
                }

                var agg: [String: UsedItem] = [:]

                for doc in snap?.documents ?? [] {
                    let data = doc.data()
                    let items = data["items"] as? [[String: Any]] ?? []

                    for it in items {
                        let part = it["partNumber"] as? String ?? ""
                        let name = it["name"] as? String ?? "(no name)"
                        let qty = it["qty"] as? Int ?? 0
                        guard !part.isEmpty, qty > 0 else { continue }

                        if let existing = agg[part] {
                            agg[part] = UsedItem(partNumber: existing.partNumber, name: existing.name, qty: existing.qty + qty)
                        } else {
                            agg[part] = UsedItem(partNumber: part, name: name, qty: qty)
                        }
                    }
                }

                self.results = agg.values.sorted { $0.qty > $1.qty }

                let totalQty = self.results.reduce(0) { $0 + $1.qty }
                self.summaryLabel.text = "Month: \(self.month)/\(self.year)\nTotal Items: \(self.results.count)\nTotal Quantity: \(totalQty)"

                self.tableView.reloadData()
            }
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
        cell.detailTextLabel?.text = "ID: \(item.partNumber) | Used Qty: \(item.qty)"
        cell.selectionStyle = .none
        return cell
    }
}

