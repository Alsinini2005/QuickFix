import Foundation

// MARK: - Models
struct InventoryItem: Codable, Hashable {
    let partNumber: String
    let name: String
    var stockQty: Int
}

struct UsedItem: Codable, Hashable {
    let partNumber: String
    let name: String
    var qty: Int
}

struct UsageLog: Codable {
    let date: Date
    let items: [UsedItem]
}

// MARK: - Notifications
extension Notification.Name {
    static let inventoryDidChange = Notification.Name("inventoryDidChange")
    static let usageDidChange = Notification.Name("usageDidChange")
}

// MARK: - Store
final class DataStore {

    static let shared = DataStore()

    private let inventoryKey = "inventory_items_v2"
    private let usageKey = "usage_logs_v2"

    private init() {
        if loadInventory().isEmpty {
            seedInventory()
        }
    }

    // MARK: Inventory
    func loadInventory() -> [InventoryItem] {
        guard let data = UserDefaults.standard.data(forKey: inventoryKey) else { return [] }
        return (try? JSONDecoder().decode([InventoryItem].self, from: data)) ?? []
    }

    func saveInventory(_ items: [InventoryItem]) {
        let data = try? JSONEncoder().encode(items)
        UserDefaults.standard.set(data, forKey: inventoryKey)
    }

    func updateStock(partNumber: String, newQty: Int) {
        var items = loadInventory()
        guard let idx = items.firstIndex(where: { $0.partNumber == partNumber }) else { return }
        items[idx].stockQty = max(0, newQty)
        saveInventory(items)
        NotificationCenter.default.post(name: .inventoryDidChange, object: nil)
    }

    // MARK: Usage
    func loadUsageLogs() -> [UsageLog] {
        guard let data = UserDefaults.standard.data(forKey: usageKey) else { return [] }
        return (try? JSONDecoder().decode([UsageLog].self, from: data)) ?? []
    }

    private func saveUsageLogs(_ logs: [UsageLog]) {
        let data = try? JSONEncoder().encode(logs)
        UserDefaults.standard.set(data, forKey: usageKey)
    }

    /// Technician finishes: deduct from inventory + add usage log (same action)
    func commitTechnicianUsedItems(_ used: [UsedItem], date: Date = Date()) {
        guard !used.isEmpty else { return }

        // Deduct from inventory
        var inventory = loadInventory()
        for u in used {
            if let idx = inventory.firstIndex(where: { $0.partNumber == u.partNumber }) {
                inventory[idx].stockQty = max(0, inventory[idx].stockQty - u.qty)
            }
        }
        saveInventory(inventory)

        // Add usage log
        var logs = loadUsageLogs()
        logs.append(UsageLog(date: date, items: used))
        saveUsageLogs(logs)

        NotificationCenter.default.post(name: .inventoryDidChange, object: nil)
        NotificationCenter.default.post(name: .usageDidChange, object: nil)
    }

    /// Monthly report aggregation
    func monthlyUsedSummary(month: Int, year: Int) -> [UsedItem] {
        let logs = loadUsageLogs()
        var totals: [String: UsedItem] = [:]
        let cal = Calendar.current

        for log in logs {
            let comps = cal.dateComponents([.year, .month], from: log.date)
            guard comps.year == year, comps.month == month else { continue }

            for item in log.items {
                if var existing = totals[item.partNumber] {
                    existing.qty += item.qty
                    totals[item.partNumber] = existing
                } else {
                    totals[item.partNumber] = item
                }
            }
        }

        return totals.values.sorted { $0.name < $1.name }
    }

    // MARK: Seed data
    private func seedInventory() {
        let seed: [InventoryItem] = [
            .init(partNumber: "IT-001", name: "Monitor Dell 24\"", stockQty: 12),
            .init(partNumber: "IT-002", name: "Monitor HP 27\"", stockQty: 8),
            .init(partNumber: "IT-003", name: "Keyboard Logitech K120", stockQty: 25),
            .init(partNumber: "IT-004", name: "Mouse USB", stockQty: 30),
            .init(partNumber: "IT-005", name: "Mouse Wireless", stockQty: 18),
            .init(partNumber: "IT-006", name: "Ethernet Cable Cat6", stockQty: 60),
            .init(partNumber: "IT-007", name: "HDMI Cable", stockQty: 40),
            .init(partNumber: "IT-008", name: "USB-C Charger 65W", stockQty: 18),
            .init(partNumber: "IT-009", name: "UPS 1200VA", stockQty: 5),
            .init(partNumber: "IT-010", name: "SSD 512GB", stockQty: 15),
            .init(partNumber: "IT-011", name: "RAM DDR4 16GB", stockQty: 20)
        ]
        saveInventory(seed)
    }
}
