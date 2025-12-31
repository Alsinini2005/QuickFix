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

final class AssignTaskVeiwController: UIViewController {
    

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var assignButton: UIButton! // connect if you have it (Assign Task button)

    // MARK: - Input (MUST be set before showing this screen)
    /// This should be the Firestore docID for the request inside StudentRepairRequests
    var requestDocId: String = ""

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var technicians: [TechnicianRow] = []
    private var selectedIndexPath: IndexPath?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Safety: avoid crashing if not connected
        tableView.dataSource = self
        tableView.delegate = self

        assignButton?.isEnabled = false

        startListeningTechnicians()
    }

    deinit { listener?.remove() }

    private func startListeningTechnicians() {
        listener?.remove()

        // Order by name if you want (requires index sometimes). If it fails, remove order.
        listener = db.collection("technicians")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }

                if let err {
                    print("❌ technicians listen error:", err.localizedDescription)
                    return
                }

                let docs = snap?.documents ?? []
                self.technicians = docs.map { TechnicianRow(doc: $0) }

                // reset selection if list changed
                self.selectedIndexPath = nil
                self.assignButton?.isEnabled = false

                self.tableView.reloadData()
                print("✅ technicians loaded:", docs.count)
            }
    }

    // MARK: - Actions
    @IBAction func didTapAssign(_ sender: UIButton) {
        guard !requestDocId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(title: "Error", message: "Missing request id (requestDocId).")
            return
        }

        guard let selectedIndexPath else {
            showAlert(title: "Select Technician", message: "Please choose a technician first.")
            return
        }

        let tech = technicians[selectedIndexPath.row]

        sender.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                try await assign(requestId: requestDocId, technician: tech)

                await MainActor.run {
                    sender.isEnabled = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(title: "Assigned", message: "Task assigned to \(tech.techName).") {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            } catch {
                await MainActor.run {
                    sender.isEnabled = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Firestore Assign Logic
    private func assign(requestId: String, technician: TechnicianRow) async throws {

        let requestRef = db.collection("StudentRepairRequests").document(requestId)
        let techRef = db.collection("technicians").document(technician.docId)

        let adminUid = Auth.auth().currentUser?.uid ?? "unknown_admin"

        // Transaction: update request + increment technician totalTasks
        try await db.runTransaction { transaction, errorPointer -> Any? in

            // Update request fields (add these fields even if not existing before)
            transaction.updateData([
                "assignedTechnicianId": technician.techId,
                "assignedTechnicianName": technician.techName,
                "assignedTechnicianDocId": technician.docId,
                "assignedAt": Timestamp(date: Date()),
                "assignedBy": adminUid,
                "status": "in_progress" // or "assigned" if you prefer
            ], forDocument: requestRef)

            // Increment technician totalTasks by 1
            transaction.updateData([
                "totalTasks": FieldValue.increment(Int64(1)),
                "updatedAt": Timestamp(date: Date())
            ], forDocument: techRef)

            return nil
        }
    }

    // MARK: - Alert helper
    private func showAlert(title: String, message: String, onOK: (() -> Void)? = nil) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOK?() })
        present(a, animated: true)
    }
}

// MARK: - UITableViewDataSource / Delegate
extension AssignTaskVeiwController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        technicians.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // ✅ Set this identifier in storyboard cell: "TechCell"
        let cell = tableView.dequeueReusableCell(withIdentifier: "TechCell", for: indexPath)

        let t = technicians[indexPath.row]
        cell.textLabel?.text = t.techName
        cell.detailTextLabel?.text = "\(t.specialization) • \(t.completedTasks)/\(t.totalTasks) completed"

        // show selection
        if indexPath == selectedIndexPath {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedIndexPath = indexPath
        assignButton?.isEnabled = true
        tableView.reloadData()
    }
}
