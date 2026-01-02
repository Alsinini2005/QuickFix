//
//  NotificationStore.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 29/12/2025.
//

import Foundation

final class NotificationStore {
    private let key = "quickfix.notifications.v1"

    func load() -> [AppNotification] {
        guard let data = UserDefaults.standard.data(forKey: key),
              let items = try? JSONDecoder().decode([AppNotification].self, from: data)
        else { return [] }
        return items
    }

    func save(_ items: [AppNotification]) {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }

    func add(_ item: AppNotification) {
        var all = load()
        all.insert(item, at: 0)
        save(all)
    }

    func markRead(id: UUID) {
        var all = load()
        if let i = all.firstIndex(where: { $0.id == id }) {
            all[i].isRead = true
            save(all)
        }
    }

    func delete(id: UUID) {
        var all = load()
        all.removeAll { $0.id == id }
        save(all)
    }
    func markAllSeen(for audience: NotificationAudience) {
        var all = load()
        var changed = false

        for i in all.indices where all[i].audience == audience && all[i].isSeen == false {
            all[i].isSeen = true
            changed = true
        }

        if changed { save(all) }
    }
}
