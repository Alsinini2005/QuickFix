import UIKit

final class AdminInventoryViewController: UIViewController {

    @IBOutlet weak var monthPicker: UIPickerView!
    @IBOutlet weak var yearField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    private let months = [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    private var inventory: [InventoryItem] = []
    private var editedStock: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Inventory Managment"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        tableView.rowHeight = 72
        tableView.keyboardDismissMode = .onDrag

        monthPicker.dataSource = self
        monthPicker.delegate = self

        // Default month/year
        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        let year = comps.year ?? Calendar.current.component(.year, from: Date())
        let month = comps.month ?? 1

        yearField.keyboardType = .numberPad
        yearField.textAlignment = .center
        yearField.text = "\(year)"
        yearField.inputAccessoryView = makeDoneToolbar()

        monthPicker.selectRow(month - 1, inComponent: 0, animated: false)

        // load inventory
        inventory = DataStore.shared.loadInventory()

        // Auto refresh when technician updates
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(reloadInventory),
                                               name: .inventoryDidChange,
                                               object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadInventory()
    }

    @objc private func reloadInventory() {
        inventory = DataStore.shared.loadInventory()
        editedStock.removeAll()
        tableView.reloadData()
    }

    // MARK: - Buttons

    @IBAction func updateTapped(_ sender: UIButton) {
        view.endEditing(true)

        // Apply edits
        for i in 0..<inventory.count {
            let partNo = inventory[i].partNumber
            if let newQty = editedStock[partNo] {
                inventory[i].stockQty = max(0, newQty)
                DataStore.shared.updateStock(partNumber: partNo, newQty: newQty)
            }
        }

        editedStock.removeAll()
        tableView.reloadData()

        let alert = UIAlertController(
            title: "Inventory Updated ✅",
            message: "The inventory quantities have been updated successfully.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    @IBAction func generateTapped(_ sender: UIButton) {
        view.endEditing(true)
        performSegue(withIdentifier: "showReport", sender: nil)
    }

    // ✅ مهم: هذا يمنع الكراش حتى لو Report داخل Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "showReport" else { return }

        let selectedMonth = monthPicker.selectedRow(inComponent: 0) + 1
        let selectedYear = Int(yearField.text ?? "") ?? Calendar.current.component(.year, from: Date())

        if let nav = segue.destination as? UINavigationController,
           let reportVC = nav.topViewController as? ReportViewController {
            reportVC.month = selectedMonth
            reportVC.year = selectedYear
            return
        }

        if let reportVC = segue.destination as? ReportViewController {
            reportVC.month = selectedMonth
            reportVC.year = selectedYear
            return
        }

        assertionFailure("Destination is not ReportViewController. Check storyboard class.")
    }

    // MARK: - Stock field

    @objc private func stockChanged(_ sender: UITextField) {
        let row = sender.tag
        guard row >= 0, row < inventory.count else { return }

        let item = inventory[row]
        let q = Int(sender.text ?? "") ?? 0
        editedStock[item.partNumber] = max(0, q)
    }

    private func makeStockField(row: Int, current: Int) -> UITextField {
        let tf = UITextField(frame: CGRect(x: 0, y: 0, width: 80, height: 32))
        tf.borderStyle = .roundedRect
        tf.keyboardType = .numberPad
        tf.textAlignment = .center
        tf.text = "\(current)"                // يظهر الرقم الحالي داخل الخانة
        tf.tag = row
        tf.addTarget(self, action: #selector(stockChanged(_:)), for: .editingChanged)
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
}

// MARK: - Table
extension AdminInventoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inventory.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "adminCell")
        let item = inventory[indexPath.row]

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "Part: \(item.partNumber) | Stock: \(item.stockQty)"
        cell.selectionStyle = .none

        cell.accessoryView = makeStockField(row: indexPath.row, current: item.stockQty)
        return cell
    }
}

// MARK: - Picker
extension AdminInventoryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { months.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        months[row]
    }
}


