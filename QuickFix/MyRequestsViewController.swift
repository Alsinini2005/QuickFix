//
//  MyRequestsViewController.swift
//  QuickFix
//
//  Shows all requests created by the current user (demo_user for now)
//  Fetches from Firestore collection: requests
//

import UIKit
import FirebaseFirestore

final class MyRequestsViewController: UITableViewController {

    private let db = Firestore.firestore()

    // Keep this consistent with Requests.swift until you add FirebaseAuth
    private let demoUserId = "demo_user"

    private var items: [MyRequestItem] = []

    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "My Requests"

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refreshPulled), for: .valueChanged)

        startListening()
    }

    deinit {
        listener?.remove()
    }

    @objc private func refreshPulled() {
        // Firestore snapshot listener will update automatically,
        // but we can force a one-time fetch as well.
        Task { await fetchOnce() }
    }

    private func startListening() {
        // Live updates
        listener?.remove()
        listener = db.collection("requests")
            .whereField("userId", isEqualTo: demoUserId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self else { return }

                if let error {
                    self.showSimpleAlert(title: "Error", message: error.localizedDescription)
                    self.refreshControl?.endRefreshing()
                    return
                }

                guard let docs = snapshot?.documents else {
                    self.items = []
                    self.tableView.reloadData()
                    self.refreshControl?.endRefreshing()
                    return
                }

                self.items = docs.compactMap { MyRequestItem(document: $0) }
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
            }
    }

    private func fetchOnce() async {
        do {
            let snap = try await db.collection("requests")
                .whereField("userId", isEqualTo: demoUserId)
                .order(by: "createdAt", descending: true)
                .getDocuments()

            items = snap.documents.compactMap { MyRequestItem(document: $0) }
            await MainActor.run {
                tableView.reloadData()
                refreshControl?.endRefreshing()
            }
        } catch {
            await MainActor.run {
                refreshControl?.endRefreshing()
                showSimpleAlert(title: "Error", message: error.localizedDescription)
            }
        }
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RequestCell", for: indexPath)

        let item = items[indexPath.row]

        // Prefer subtitle style if available; otherwise configure default
        var content = cell.defaultContentConfiguration()
        content.text = item.titleLine
        content.secondaryText = item.subtitleLine
        cell.contentConfiguration = content

        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // Optional: show details on tap (simple alert for now)
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let item = items[indexPath.row]
        let msg = [
            "Campus: \(item.campus)",
            "Building: \(item.building)",
            "Classroom: \(item.classroom)",
            "Status: \(item.status)",
            "",
            item.problemDescription
        ].joined(separator: "\n")

        showSimpleAlert(title: "Request", message: msg)
    }

    private func showSimpleAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - View model

private struct MyRequestItem {
    let id: String
    let campus: String
    let building: String
    let classroom: String
    let problemDescription: String
    let status: String
    let createdAt: Date?

    init?(document: QueryDocumentSnapshot) {
        let data = document.data()

        self.id = document.documentID
        self.campus = data["campus"] as? String ?? ""
        self.building = data["building"] as? String ?? ""
        self.classroom = data["classroom"] as? String ?? ""
        self.problemDescription = data["problemDescription"] as? String ?? ""
        self.status = data["status"] as? String ?? "submitted"

        if let ts = data["createdAt"] as? Timestamp {
            self.createdAt = ts.dateValue()
        } else {
            self.createdAt = nil
        }
    }

    var titleLine: String {
        // Example: "Campus - 10A - 201"
        let parts = [campus, building, classroom].filter { !$0.isEmpty }
        return parts.isEmpty ? "Request" : parts.joined(separator: " - ")
    }

    var subtitleLine: String {
        var pieces: [String] = []
        if let createdAt {
            pieces.append(Self.dateFormatter.string(from: createdAt))
        }
        pieces.append("Status: \(status)")
        return pieces.joined(separator: " • ")
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()
}
