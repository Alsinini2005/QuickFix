import UIKit
import FirebaseFirestore

import Foundation

// Firebase is the database. These are just models for UI.
struct InventoryItem: Hashable {
    let partNumber: String   // Firestore documentID
    let name: String
    let stockQty: Int        // Firestore "quantity"
}

struct UsedItem: Hashable {
    let partNumber: String   // Firestore documentID
    let name: String
    let qty: Int
}


final class AdminInventoryViewController: UIViewController {

    @IBOutlet weak var monthPicker: UIPickerView!
    @IBOutlet weak var yearField: UITextField!
    @IBOutlet weak var tableView: UITableView!

    private let db = Firestore.firestore()
    private var invListener: ListenerRegistration?

    private let months = [
        "January","February","March","April","May","June",
        "July","August","September","October","November","December"
    ]

    private var inventory: [InventoryItem] = []
    private var editedStock: [String: Int] = [:]   // docId -> newQty

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

        let comps = Calendar.current.dateComponents([.year, .month], from: Date())
        let year = comps.year ?? Calendar.current.component(.year, from: Date())
        let month = comps.month ?? 1

        yearField.keyboardType = .numberPad
        yearField.textAlignment = .center
        yearField.text = "\(year)"
        monthPicker.selectRow(month - 1, inComponent: 0, animated: false)

        // ✅ No Done toolbar — tap anywhere to dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)

        startListeningInventory()
    }

    deinit {
        invListener?.remove()
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    private func startListeningInventory() {
        invListener?.remove()

        invListener = db.collection("inventory")
            .order(by: "name")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err = err {
                    print("Inventory listen error:", err)
                    return
                }

                self.inventory = (snap?.documents ?? []).map { doc in
                    let data = doc.data()
                    return InventoryItem(
                        partNumber: doc.documentID,
                        name: data["name"] as? String ?? "(no name)",
                        stockQty: data["quantity"] as? Int ?? 0
                    )
                }

                self.editedStock.removeAll()
                self.tableView.reloadData()
            }
    }

    @IBAction func updateTapped(_ sender: UIButton) {
        view.endEditing(true)

        if editedStock.isEmpty {
            let alert = UIAlertController(title: "No Changes", message: "Nothing to update.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }

        let batch = db.batch()
        for (docId, newQty) in editedStock {
            let ref = db.collection("inventory").document(docId)
            batch.updateData([
                "quantity": max(0, newQty),
                "lastUpdated": FieldValue.serverTimestamp()
            ], forDocument: ref)
        }

        batch.commit { [weak self] err in
            guard let self else { return }

            if let err = err {
                let alert = UIAlertController(title: "Failed ⚠️", message: err.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }

            self.editedStock.removeAll()

            let alert = UIAlertController(
                title: "Inventory Updated ✅",
                message: "The inventory quantities have been updated successfully.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }

    @IBAction func generateTapped(_ sender: UIButton) {
        view.endEditing(true)
        performSegue(withIdentifier: "showReport", sender: nil)
    }

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
    }

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
        tf.text = "\(current)"
        tf.tag = row
        tf.addTarget(self, action: #selector(stockChanged(_:)), for: .editingChanged)
        tf.semanticContentAttribute = .forceLeftToRight
        return tf
    }
}

extension AdminInventoryViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        inventory.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "adminCell")
        let item = inventory[indexPath.row]

        cell.textLabel?.text = item.name
        cell.detailTextLabel?.text = "ID: \(item.partNumber) | Stock: \(item.stockQty)"
        cell.selectionStyle = .none
        cell.accessoryView = makeStockField(row: indexPath.row, current: item.stockQty)

        return cell
    }
}

extension AdminInventoryViewController: UIPickerViewDataSource, UIPickerViewDelegate {
    func numberOfComponents(in pickerView: UIPickerView) -> Int { 1 }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int { months.count }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        months[row]
    }
}

