import UIKit

final class TechnicianLogViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    private var allInventory: [InventoryItem] = []
    private var filtered: [InventoryItem] = []

    // partNumber -> typed qty
    private var typedQty: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Log Inventory"
        view.backgroundColor = .systemBackground

        allInventory = DataStore.shared.loadInventory()
        filtered = allInventory

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.rowHeight = 72
        tableView.keyboardDismissMode = .onDrag

        // optional: live refresh if something changes
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadInventory),
                                               name: .inventoryDidChange,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func reloadInventory() {
        allInventory = DataStore.shared.loadInventory()
        applyFilter(searchBar.text ?? "")
        tableView.reloadData()
    }

    @IBAction func finishTapped(_ sender: UIButton) {
        view.endEditing(true)

        let used = buildUsedItems()
        if used.isEmpty {
            let alert = UIAlertController(
                title: "No Items ⚠️",
                message: "Please enter a quantity for at least one item.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        DataStore.shared.commitTechnicianUsedItems(used)

        // Reset inputs + refresh UI
        typedQty.removeAll()
        reloadInventory()

        let alert = UIAlertController(
            title: "Done ✅",
            message: "Items logged successfully and inventory updated.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK 👍", style: .default))
        present(alert, animated: true)
    }

    private func buildUsedItems() -> [UsedItem] {
        var result: [UsedItem] = []
        for item in allInventory {
            let q = typedQty[item.partNumber] ?? 0
            if q > 0 {
                result.append(.init(partNumber: item.partNumber, name: item.name, qty: q))
            }
        }
        return result
    }

    @objc private func qtyChanged(_ sender: UITextField) {
        let row = sender.tag
        guard row >= 0, row < filtered.count else { return }

        let inv = filtered[row]
        let q = Int(sender.text ?? "") ?? 0

        if q <= 0 { typedQty[inv.partNumber] = nil }
        else { typedQty[inv.partNumber] = q }

        tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
    }

    private func makeQtyField(row: Int, value: Int) -> UITextField {
        let tf = UITextField(frame: CGRect(x: 0, y: 0, width: 65, height: 32))
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.placeholder = "Qty"
        tf.tag = row
        tf.text = value > 0 ? "\(value)" : ""
        tf.addTarget(self, action: #selector(qtyChanged(_:)), for: .editingChanged)
        tf.inputAccessoryView = makeDoneToolbar()
        tf.semanticContentAttribute = .forceLeftToRight
        return tf
    }

    private func makeDoneToolbar() -> UIToolbar {
        let tb = UIToolbar()
        tb.sizeToFit()
        tb.items = [
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(doneEditing))
        ]
        return tb
    }

    @objc private func doneEditing() {
        view.endEditing(true)
    }

    private func applyFilter(_ text: String) {
        let q = text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if q.isEmpty {
            filtered = allInventory
        } else {
            filtered = allInventory.filter {
                $0.name.lowercased().contains(q) || $0.partNumber.lowercased().contains(q)
            }
        }
    }
}

// MARK: - Table
extension TechnicianLogViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "techCell")
        let inv = filtered[indexPath.row]

        cell.textLabel?.text = "\(inv.name)   (Stock: \(inv.stockQty))"
        cell.detailTextLabel?.text = "Part: \(inv.partNumber)"
        cell.selectionStyle = .none

        let q = typedQty[inv.partNumber] ?? 0
        cell.accessoryType = (q > 0) ? .checkmark : .none
        cell.accessoryView = makeQtyField(row: indexPath.row, value: q)

        return cell
    }
}

// MARK: - Search
extension TechnicianLogViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        applyFilter(searchText)
        tableView.reloadData()
    }
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
}

