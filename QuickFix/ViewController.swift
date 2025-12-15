import UIKit

final class ViewController: UIViewController {

    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var generateButton: UIButton!

    struct Part {
        let name: String
        let partNumber: String
    }

    struct ReportItem {
        let name: String
        let partNumber: String
        let quantity: Int
    }

    private let allParts: [Part] = [
        Part(name: "Monitor Dell 24\"", partNumber: "IT-001"),
        Part(name: "Monitor HP 27\"", partNumber: "IT-002"),
        Part(name: "Keyboard Logitech K120", partNumber: "IT-003"),
        Part(name: "Keyboard Mechanical", partNumber: "IT-004"),
        Part(name: "Mouse USB", partNumber: "IT-005"),
        Part(name: "Mouse Wireless", partNumber: "IT-006"),
        Part(name: "Ethernet Cable Cat6", partNumber: "IT-007"),
        Part(name: "HDMI Cable", partNumber: "IT-008"),
        Part(name: "USB-C Charger 65W", partNumber: "IT-009"),
        Part(name: "UPS 1200VA", partNumber: "IT-010")
    ]

    private var filteredParts: [Part] = []
    private var selectedPartNumbers: Set<String> = []

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Log Inventory"
        view.backgroundColor = .systemBackground

        filteredParts = allParts

        tableView.dataSource = self
        tableView.delegate = self
        searchBar.delegate = self

        tableView.rowHeight = 64
        tableView.allowsMultipleSelection = true

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Finish",
            style: .done,
            target: self,
            action: #selector(finishTapped)
        )

        generateButton.layer.cornerRadius = 14
        generateButton.backgroundColor = UIColor(red: 0.14, green: 0.33, blue: 0.41, alpha: 1.0)
        generateButton.setTitleColor(.white, for: .normal)
    }

    @objc private func finishTapped() {
        let alert = UIAlertController(
            title: "✅ Success",
            message: "🎉 You selected successfully!",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK 👍", style: .default))
        present(alert, animated: true)
    }

    @IBAction func generateButtonTapped(_ sender: UIButton) {
        performSegue(withIdentifier: "showReport", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showReport",
           let reportVC = segue.destination as? ReportViewController {
            reportVC.items = selectedItems()
        }
    }

    private func selectedItems() -> [ReportItem] {
        allParts.compactMap { part in
            guard selectedPartNumbers.contains(part.partNumber) else { return nil }
            return ReportItem(
                name: part.name,
                partNumber: part.partNumber,
                quantity: 1 // ثابت
            )
        }
    }
}

// MARK: - TableView
extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filteredParts.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let part = filteredParts[indexPath.row]

        cell.textLabel?.text = part.name
        cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)

        cell.detailTextLabel?.text = "Part Number: \(part.partNumber)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12)
        cell.detailTextLabel?.textColor = .secondaryLabel

        // ✔️ checkmark إذا مختار
        cell.accessoryType =
            selectedPartNumbers.contains(part.partNumber) ? .checkmark : .none

        return cell
    }

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        let part = filteredParts[indexPath.row]
        selectedPartNumbers.insert(part.partNumber)
        tableView.reloadRows(at: [indexPath], with: .none)
    }

    func tableView(_ tableView: UITableView,
                   didDeselectRowAt indexPath: IndexPath) {

        let part = filteredParts[indexPath.row]
        selectedPartNumbers.remove(part.partNumber)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

// MARK: - Search
extension ViewController: UISearchBarDelegate {

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let q = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if q.isEmpty {
            filteredParts = allParts
        } else {
            filteredParts = allParts.filter {
                $0.name.lowercased().contains(q) ||
                $0.partNumber.lowercased().contains(q)
            }
        }
        tableView.reloadData()
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
}

