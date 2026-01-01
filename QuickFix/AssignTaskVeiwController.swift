import UIKit
import FirebaseFirestore
import FirebaseAuth

// MARK: - Model
private struct TechnicianRow {
    let docId: String
    let techId: String
    let techName: String
    let specialization: String
    let completedTasks: Int
    let totalTasks: Int

    init(doc: QueryDocumentSnapshot) {
        let d = doc.data()
        self.docId = doc.documentID
        self.techId = (d["techId"] as? String) ?? doc.documentID
        self.techName = (d["techName"] as? String) ?? "Unknown"
        self.specialization = (d["specialization"] as? String) ?? "—"
        self.completedTasks = (d["completedTasks"] as? Int) ?? 0
        self.totalTasks = (d["totalTasks"] as? Int) ?? 0
    }
}

final class AssignTaskVeiwController: UITableViewController {

    var requestDocId: String = ""

    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private var technicians: [TechnicianRow] = []
    private var selectedIndexPath: IndexPath?

    private let assignButton = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAssignButton()
        startListeningTechnicians()
    }

    deinit { listener?.remove() }

    // MARK: - Bottom Button
    private func setupAssignButton() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.width, height: 90))

        assignButton.setTitle("Assign Task", for: .normal)
        assignButton.isEnabled = false
        assignButton.backgroundColor = .systemBlue
        assignButton.setTitleColor(.white, for: .normal)
        assignButton.layer.cornerRadius = 12
        assignButton.addTarget(self, action: #selector(didTapAssign), for: .touchUpInside)

        assignButton.frame = CGRect(x: 16, y: 20, width: view.frame.width - 32, height: 50)
        container.addSubview(assignButton)

        tableView.tableFooterView = container
    }

    // MARK: - Firestore
    private func startListeningTechnicians() {
        listener?.remove()

        listener = db.collection("technicians")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    print("❌ technicians listen error:", err.localizedDescription)
                    return
                }

                self.technicians = snap?.documents.map {
                    TechnicianRow(doc: $0)
                } ?? []

                self.selectedIndexPath = nil
                self.assignButton.isEnabled = false
                self.tableView.reloadData()
            }
    }

    // MARK: - Assign
    @objc private func didTapAssign() {
        guard !requestDocId.isEmpty else {
            showAssignedAndGoBack(techName: "")
            return
        }


        guard let indexPath = selectedIndexPath else {
            showAlert(title: "Select Technician", message: "Please choose a technician.")
            return
        }

        let tech = technicians[indexPath.row]

        assignButton.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                try await assign(requestId: requestDocId, technician: tech)
                await MainActor.run {
                    self.view.isUserInteractionEnabled = true
                    self.showAssignedAndGoBack(techName: tech.techName)
                }
            } catch {
                await MainActor.run {
                    self.view.isUserInteractionEnabled = true
                    self.assignButton.isEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    private func assign(requestId: String, technician: TechnicianRow) async throws {
        let requestRef = db.collection("StudentRepairRequests").document(requestId)
        let techRef = db.collection("technicians").document(technician.docId)
        let adminUid = Auth.auth().currentUser?.uid ?? "unknown_admin"

        _ = try await db.runTransaction { transaction, _ -> Any? in
            transaction.updateData([
                "assignedTechnicianId": technician.techId,
                "assignedTechnicianName": technician.techName,
                "assignedTechnicianDocId": technician.docId,
                "assignedAt": Timestamp(date: Date()),
                "assignedBy": adminUid,
                "status": "in_progress"
            ], forDocument: requestRef)

            transaction.updateData([
                "totalTasks": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ], forDocument: techRef)

            return nil
        }
    }

    // MARK: - Alerts
    private func showAssignedAndGoBack(techName: String) {
        let alert = UIAlertController(
            title: "Assigned Successfully",
            message: "The task has been assigned successfully.",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
        })

        present(alert, animated: true)
    }


    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Table
extension AssignTaskVeiwController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        technicians.count
    }

    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TechCell", for: indexPath)

        let t = technicians[indexPath.row]
        cell.textLabel?.text = t.techName
        cell.detailTextLabel?.text =
        "\(t.specialization) • \(t.completedTasks)/\(t.totalTasks) completed"
        cell.accessoryType = indexPath == selectedIndexPath ? .checkmark : .none

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        assignButton.isEnabled = true
        tableView.reloadData()
    }
}
