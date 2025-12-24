//
//  AdminReportViewController.swift
//  QuickFix
//
//  Admin can generate Monthly and Yearly reports
//

import UIKit
import FirebaseFirestore

final class AdminReportViewController: UIViewController {

    // MARK: - Outlets (Storyboard)
    @IBOutlet weak var monthlyFromPicker: UIDatePicker!
    @IBOutlet weak var monthlyToPicker: UIDatePicker!

    @IBOutlet weak var yearlyFromPicker: UIDatePicker!
    @IBOutlet weak var yearlyToPicker: UIDatePicker!

    // MARK: - Firebase
    private let db = Firestore.firestore()

    // Temporary admin id (replace later with Firebase Auth)
    private let adminId = "admin_demo"

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        configurePickers()
    }

    private func configurePickers() {
        // Optional safety
        let today = Date()
        monthlyFromPicker.maximumDate = today
        monthlyToPicker.maximumDate = today
        yearlyFromPicker.maximumDate = today
        yearlyToPicker.maximumDate = today
    }

    // MARK: - Actions

    /// Monthly Generate button
    @IBAction func generateMonthlyTapped(_ sender: UIButton) {
        Task {
            sender.isEnabled = false
            do {
                let start = startOfDay(monthlyFromPicker.date)
                let end = endExclusive(monthlyToPicker.date)

                try validateDateRange(start: start, end: end)

                try await generateReport(
                    type: "monthly",
                    start: start,
                    endExclusive: end
                )

                showAlert(title: "Done", message: "Monthly report generated ✅")
            } catch {
                showAlert(title: "Error", message: error.localizedDescription)
            }
            sender.isEnabled = true
        }
    }

    /// Yearly Generate button
    @IBAction func generateYearlyTapped(_ sender: UIButton) {
        Task {
            sender.isEnabled = false
            do {
                let start = startOfDay(yearlyFromPicker.date)
                let end = endExclusive(yearlyToPicker.date)

                try validateDateRange(start: start, end: end)

                try await generateReport(
                    type: "yearly",
                    start: start,
                    endExclusive: end
                )

                showAlert(title: "Done", message: "Yearly report generated ✅")
            } catch {
                showAlert(title: "Error", message: error.localizedDescription)
            }
            sender.isEnabled = true
        }
    }

    // MARK: - Report generation logic

    private func generateReport(
        type: String,
        start: Date,
        endExclusive: Date
    ) async throws {

        let snapshot = try await db.collection("requests")
            .whereField("createdAt", isGreaterThanOrEqualTo: Timestamp(date: start))
            .whereField("createdAt", isLessThan: Timestamp(date: endExclusive))
            .getDocuments()

        var totalAssigned = 0
        var totalResolved = 0
        var technicianStats: [String: [String: Int]] = [:]

        for doc in snapshot.documents {
            let data = doc.data()

            let technicianId = data["technicianId"] as? String ?? "unassigned"
            let status = data["status"] as? String ?? "submitted"

            if technicianId != "unassigned" {
                totalAssigned += 1

                var stats = technicianStats[technicianId] ?? [
                    "assigned": 0,
                    "resolved": 0
                ]

                stats["assigned", default: 0] += 1

                if status == "resolved" {
                    stats["resolved", default: 0] += 1
                    totalResolved += 1
                }

                technicianStats[technicianId] = stats
            }
        }

        let payload: [String: Any] = [
            "type": type,
            "periodStart": Timestamp(date: start),
            "periodEnd": Timestamp(date: endExclusive),
            "createdAt": FieldValue.serverTimestamp(),
            "createdBy": adminId,
            "totals": [
                "assigned": totalAssigned,
                "resolved": totalResolved
            ],
            "byTechnician": technicianStats
        ]

        try await db.collection("adminReports").addDocument(data: payload)
    }

    // MARK: - Helpers

    private func validateDateRange(start: Date, end: Date) throws {
        guard start < end else {
            throw NSError(
                domain: "Validation",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "From date must be before To date."]
            )
        }
    }

    private func startOfDay(_ date: Date) -> Date {
        Calendar.current.startOfDay(for: date)
    }

    /// Firestore-friendly exclusive end (next day at 00:00)
    private func endExclusive(_ date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: 1,
                              to: Calendar.current.startOfDay(for: date))!
    }

    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title,
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
