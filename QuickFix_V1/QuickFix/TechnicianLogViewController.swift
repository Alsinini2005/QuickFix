import UIKit
import FirebaseFirestore

final class TechnicianLogViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!

    // Firebase
    private let db = Firestore.firestore()
    private var invListener: ListenerRegistration?

    // UI Models (Firebase docID as partNumber)
    private var allInventory: [InventoryItem] = []
    private var filtered: [InventoryItem] = []

    // partNumber(docID) -> typed qty
    private var typedQty: [String: Int] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Log Inventory"
        view.backgroundColor = .systemBackground

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.rowHeight = 72
        tableView.keyboardDismissMode = .onDrag

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

    // MARK: - Firestore Listen
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

                let items: [InventoryItem] = (snap?.documents ?? []).map { doc in
                    let data = doc.data()
                    let name = data["name"] as? String ?? "(no name)"
                    let qty = data["quantity"] as? Int ?? 0

                    return InventoryItem(
                        partNumber: doc.documentID,
                        name: name,
                        stockQty: qty
                    )
                }

                self.allInventory = items
                self.applyFilter(self.searchBar.text ?? "")
                self.tableView.reloadData()
            }
    }

    // MARK: - Actions
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

        commitUsedItemsTransaction(used: used)
    }

    // MARK: - Build used items
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

    // MARK: - Transaction (multi-item safe)
    private func commitUsedItemsTransaction(used: [UsedItem]) {
        let logsRef = db.collection("usageLogs").document()

        let now = Date()
        let comps = Calendar.current.dateComponents([.month, .year], from: now)
        let month = comps.month ?? 1
        let year = comps.year ?? Calendar.current.component(.year, from: now)

        db.runTransaction({ txn, errorPointer -> Any? in

            // 1) READ ALL first
            var currentQtyById: [String: Int] = [:]

            for u in used {
                let invRef = self.db.collection("inventory").document(u.partNumber)

                let snap: DocumentSnapshot
                do {
                    snap = try txn.getDocument(invRef)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }

                let currentQty = snap.data()?["quantity"] as? Int ?? 0
                currentQtyById[u.partNumber] = currentQty
            }

            // 2) Validate ALL
            for u in used {
                let currentQty = currentQtyById[u.partNumber] ?? 0
                if u.qty > currentQty {
                    let err = NSError(
                        domain: "Inventory",
                        code: 400,
                        userInfo: [NSLocalizedDescriptionKey:
                                    "Not enough stock for \(u.name).\nAvailable: \(currentQty)\nRequested: \(u.qty)"
                                  ]
                    )
                    errorPointer?.pointee = err
                    return nil
                }
            }

            // 3) WRITE ALL after validation
            for u in used {
                let invRef = self.db.collection("inventory").document(u.partNumber)
                let currentQty = currentQtyById[u.partNumber] ?? 0

                txn.updateData([
                    "quantity": currentQty - u.qty,
                    "lastUpdated": FieldValue.serverTimestamp()
                ], forDocument: invRef)
            }

            // 4) Write usage log
            let itemsArr: [[String: Any]] = used.map { u in
                [
                    "partNumber": u.partNumber,
                    "name": u.name,
                    "qty": u.qty
                ]
            }

            txn.setData([
                "createdAt": FieldValue.serverTimestamp(),
                "month": month,
                "year": year,
                "items": itemsArr
            ], forDocument: logsRef)

            return nil

        }, completion: { [weak self] _, err in
            guard let self else { return }

            if let err = err {
                let alert = UIAlertController(
                    title: "Failed ⚠️",
                    message: err.localizedDescription,
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default))
                self.present(alert, animated: true)
                return
            }

            self.typedQty.removeAll()
            self.applyFilter(self.searchBar.text ?? "")
            self.tableView.reloadData()

            let alert = UIAlertController(
                title: "Success ✅",
                message: "Items logged successfully and inventory updated.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        })
    }

    // MARK: - Qty input handling
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
        tf.semanticContentAttribute = .forceLeftToRight
        return tf
    }

    // MARK: - Search filter
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
        cell.detailTextLabel?.text = "ID: \(inv.partNumber)"
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

