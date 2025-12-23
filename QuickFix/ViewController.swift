import UIKit

final class TechnicianTasksViewController: UIViewController {

@IBOutlet private weak var tableView: UITableView!
@IBOutlet private weak var acceptButton: UIButton!
@IBOutlet private weak var rejectButton: UIButton!

// Initial tasks (title + details)
private let initialTasks: [(title: String, details: String)] = [
("Replace network cable", "Room: 204 • Building: IT Block"),
("Fix printer issue", "Room: Admin Office • Floor: 1"),
("Install software", "Lab: Computer Lab 3"),
("Check UPS status", "Location: Server Room"),
("Configure workstation", "Room: HR Office"),
("Update antivirus", "Department: Faculty"),
("Troubleshoot Wi-Fi", "Area: Library"),
("Replace keyboard", "Lab: Lab 3"),
("Backup files", "Department: Finance"),
("Inspect network switch", "Location: IT Room")
]

private var tasks: [(title: String, details: String)] = []
private var selectedTasks = Set<Int>()

override func viewDidLoad() {
super.viewDidLoad()

view.backgroundColor = .systemBackground

tasks = initialTasks

tableView.dataSource = self
tableView.delegate = self
tableView.tableFooterView = UIView()
tableView.rowHeight = UITableView.automaticDimension
tableView.estimatedRowHeight = 72

acceptButton.layer.cornerRadius = 12
rejectButton.layer.cornerRadius = 12

updateButtonsState()
}

// MARK: - Actions

@IBAction private func acceptPressed(_ sender: UIButton) {
guard !selectedTasks.isEmpty else {
showInfoAlert(title: "No Selection", message: "Please select at least one task.")
return
}

let chosen = selectedTasks.sorted().map { tasks[$0].title }
let message = chosen.map { "• \($0)" }.joined(separator: "\n")

let alert = UIAlertController(
title: "Thank You",
message: "You accepted the following task(s):\n\n\(message)",
preferredStyle: .alert
)

alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
self?.removeSelectedTasks()
})

present(alert, animated: true)
}

@IBAction private func rejectPressed(_ sender: UIButton) {
guard !selectedTasks.isEmpty else {
showInfoAlert(title: "No Selection", message: "Please select at least one task.")
return
}

let alert = UIAlertController(
title: "Reject Task",
message: "Please write the reason for rejecting the selected task(s).",
preferredStyle: .alert
)

alert.addTextField { tf in
tf.placeholder = "Reason..."
}

alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))

alert.addAction(UIAlertAction(title: "Submit", style: .destructive) { [weak self] _ in
self?.removeSelectedTasks()
})

present(alert, animated: true)
}

// MARK: - Helpers

private func removeSelectedTasks() {
let indexes = selectedTasks.sorted(by: >)
for index in indexes {
tasks.remove(at: index)
}
selectedTasks.removeAll()
tableView.reloadData()
updateButtonsState()
}

private func updateButtonsState() {
let enabled = !selectedTasks.isEmpty
acceptButton.isEnabled = enabled
rejectButton.isEnabled = enabled
acceptButton.alpha = enabled ? 1.0 : 0.5
rejectButton.alpha = enabled ? 1.0 : 0.5
}

private func showInfoAlert(title: String, message: String) {
let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
alert.addAction(UIAlertAction(title: "OK", style: .default))
present(alert, animated: true)
}
}

// MARK: - TableView

extension TechnicianTasksViewController: UITableViewDataSource, UITableViewDelegate {

func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
tasks.count
}

func tableView(_ tableView: UITableView,
cellForRowAt indexPath: IndexPath) -> UITableViewCell {

let cell = UITableViewCell(style: .subtitle, reuseIdentifier: "TaskCell")
cell.selectionStyle = .none

let task = tasks[indexPath.row]

cell.textLabel?.text = task.title
cell.textLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
cell.textLabel?.numberOfLines = 1

cell.detailTextLabel?.text = task.details
cell.detailTextLabel?.font = .systemFont(ofSize: 13)
cell.detailTextLabel?.textColor = .secondaryLabel
cell.detailTextLabel?.numberOfLines = 1

if selectedTasks.contains(indexPath.row) {
cell.accessoryType = .checkmark
} else {
cell.accessoryType = .none
}

return cell
}

func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
tableView.deselectRow(at: indexPath, animated: true)

if selectedTasks.contains(indexPath.row) {
selectedTasks.remove(indexPath.row)
} else {
selectedTasks.insert(indexPath.row)
}

tableView.reloadRows(at: [indexPath], with: .automatic)
updateButtonsState()
}
}
