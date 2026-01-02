//
//  AdminReportDocReceivable.swift
//  QuickFix
//
//  Created by BP-36-212-12 on 30/12/2025.
//

import Foundation

protocol AdminReportDocReceivable: AnyObject {
    var docId: String? { get set }
    var reportType: String? { get set }   // "monthly" / "yearly"
}

