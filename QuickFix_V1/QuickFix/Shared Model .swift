//
//  Shared Model .swift
//  QuickFix
//
//  Created by BP-36-212-12 on 30/12/2025.
//

import Foundation
import FirebaseFirestore

struct TechnicianReportTotals: Hashable {
    let assigned: Int
    let completed: Int
}

struct ReportItem {
    let docId: String
    let type: String
    let createdAt: Date
    let periodStart: Date
    let periodEnd: Date
    let createdBy: String
    let totals: [String: Int]
    /// technicianId -> totals
    let byTechnician: [String: TechnicianReportTotals]

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]

        guard
            let type = data["type"] as? String,
            let periodStart = (data["periodStart"] as? Timestamp)?.dateValue(),
            let periodEnd = (data["periodEnd"] as? Timestamp)?.dateValue(),
            let createdBy = data["createdBy"] as? String
        else { return nil }

        // createdAt can be temporarily missing when using FieldValue.serverTimestamp()
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()

        self.docId = doc.documentID
        self.type = type
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.createdBy = createdBy
        self.totals = data["totals"] as? [String: Int] ?? [:]

        // byTechnician is saved as a nested map: technicianId -> { assigned: Int, completed: Int }
        let rawByTech = data["byTechnician"] as? [String: Any] ?? [:]
        var parsed: [String: TechnicianReportTotals] = [:]
        for (techId, value) in rawByTech {
            if let dict = value as? [String: Any] {
                let assigned = dict["assigned"] as? Int ?? 0
                let completed = dict["completed"] as? Int ?? 0
                parsed[techId] = TechnicianReportTotals(assigned: assigned, completed: completed)
            }
        }
        self.byTechnician = parsed
    }
}
