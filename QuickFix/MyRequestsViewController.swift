//
//  MyRequestsViewController.swift
//  QuickFix
//
//  Shows all requests created by the user from Firestore in a UITableView.
//  Realtime updates via addSnapshotListener.
//

import UIKit
import FirebaseFirestore

final class MyRequestsViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Data
    private var requests: [RequestRow] = []

    // For now (no Auth). Must match what you save in Requests page.
    private let demoUserId = "demo_user"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupTable()
        startListeningForRequests()
    }

    deinit {
        listener?.remove()
    }

    // MARK: - Setup
    private func setupTable() {
        tableView.dataSource = self
        tableView.delegate = self

        // If you are using a prototype cell in storyboard with Identifier = "RequestCell"
        // you DO NOT need to register anything here.
        // If you are NOT using a prototype cell, uncomment below and use a basic cell:
        // tableView.register(UITableViewCell.self, forCellReuseIdentifier: "RequestCell")
    }

    // MARK: - Firestore
    private func startListeningForRequests() {
        // Stop any existing listener (safety)
        listener?.remove()

        listener = db.collection("requests")
            .whereField("userId", isEqualTo: demoUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    print("Firestore listen error:", error)
                    return
                }

                guard let snapshot else {
                    self.requests = []
                    self.tableView.reloadData()
                    return
                }

                self.requests = snapshot.documents.compactMap { doc in
                    RequestRow.from(doc: doc)
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            }
    }
}

// MARK: - UITableViewDataSource
extension MyRequestsViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        requests.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)
        let item = requests[indexPath.row]

        var content = cell.defaultContentConfiguration()
        content.text = "\(item.campus) - \(item.building) - \(item.classroom)"

        let dateText = item.createdAt.formatted(date: .abbreviated, time: .shortened)
        content.secondaryText = "\(dateText) • Status: \(item.status)"

        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MyRequestsViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = requests[indexPath.row]
        let msg =
        """
        Campus: \(item.campus)
        Building: \(item.building)
        Classroom: \(item.classroom)

        Status: \(item.status)

        Description:
        \(item.problemDescription)
        """

        let a = UIAlertController(title: "Request Details", message: msg, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Model used by this screen
private struct RequestRow {
    let id: String
    let campus: String
    let building: String
    let classroom: String
    let problemDescription: String
    let status: String
    let createdAt: Date
    let imageUrl: String?

    static func from(doc: QueryDocumentSnapshot) -> RequestRow? {
        let data = doc.data()

        let campus = data["campus"] as? String ?? ""
        let building = data["building"] as? String ?? ""
        let classroom = data["classroom"] as? String ?? ""
        let problemDescription = data["problemDescription"] as? String ?? ""
        let status = data["status"] as? String ?? "submitted"
        let imageUrl = data["imageUrl"] as? String

        // createdAt is serverTimestamp. It may be nil briefly right after creation.
        let ts = data["createdAt"] as? Timestamp
        let createdAt = ts?.dateValue() ?? Date()

        // If key fields are empty, you can decide to drop the row (optional)
        if campus.isEmpty && building.isEmpty && classroom.isEmpty && problemDescription.isEmpty {
            // Still return it if you want; I’m filtering totally-empty docs out:
            return nil
        }

        return RequestRow(
            id: doc.documentID,
            campus: campus,
            building: building,
            classroom: classroom,
            problemDescription: problemDescription,
            status: status,
            createdAt: createdAt,
            imageUrl: imageUrl
        )
    }
}
