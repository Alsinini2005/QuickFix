//
//  Shared Model .swift
//  QuickFix
//
//  Created by BP-36-212-12 on 30/12/2025.
//

import Foundation
import FirebaseFirestore

struct ReportItem {
    let docId: String
    let type: String
    let createdAt: Date
    let periodStart: Date
    let periodEnd: Date
    let createdBy: String
    let totals: [String: Int]
    let byTechnician: [String: Int]

    init?(doc: DocumentSnapshot) {
        let data = doc.data() ?? [:]

        guard
            let type = data["type"] as? String,
            let createdAt = (data["createdAt"] as? Timestamp)?.dateValue(),
            let periodStart = (data["periodStart"] as? Timestamp)?.dateValue(),
            let periodEnd = (data["periodEnd"] as? Timestamp)?.dateValue(),
            let createdBy = data["createdBy"] as? String
        else { return nil }

        self.docId = doc.documentID
        self.type = type
        self.createdAt = createdAt
        self.periodStart = periodStart
        self.periodEnd = periodEnd
        self.createdBy = createdBy
        self.totals = data["totals"] as? [String: Int] ?? [:]
        self.byTechnician = data["byTechnician"] as? [String: Int] ?? [:]
    }
}
