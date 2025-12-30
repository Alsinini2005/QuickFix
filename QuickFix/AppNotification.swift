//
//  AppNotification.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 29/12/2025.
//

import Foundation

enum NotificationAudience: String, Codable {
    case user, admin, technician
}

enum NotificationCategory: String, Codable {
    case assignment      // New Assignment
    case statusUpdate    // Status Update
    case overdueAlert    // OVERDUE ALERT
    case systemAlert     // System Alerts
}

struct AppNotification: Codable, Identifiable {
    let id: UUID
    let audience: NotificationAudience
    let category: NotificationCategory
    let title: String
    let message: String
    let createdAt: Date
    var isRead: Bool
    var isSeen: Bool
    var ticketId: UUID?
    
}
