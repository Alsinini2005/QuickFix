//
//  AutoRulesStore.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 25/12/2025.
//

import Foundation

// MARK: - Models


enum PriorityLevel: String, Codable, CaseIterable {
    case low = "LOW"
    case medium = "MEDIUM"
    case high = "HIGH"
    case urgent = "URGENT"
}

struct AutoRuleCondition: Codable {
    var location: String?
    var category: String?
    var timeLimitHours: Int?
}

struct AutoRule: Codable, Identifiable {
    var id: UUID = UUID()
    var name: String
    var condition: AutoRuleCondition
    var setPriorityTo: PriorityLevel
    var notifyAdmins: Bool
    var isEnabled: Bool
}

struct AutoRulesSettings: Codable {
    var manualOverrideAllowed: Bool
    var rules: [AutoRule]

    static let `default` = AutoRulesSettings(
        manualOverrideAllowed: true,
        rules: [
            AutoRule(
                name: "Rule 1: Location Urgency",
                condition: .init(location: "Server Room", category: nil, timeLimitHours: nil),
                setPriorityTo: .urgent,
                notifyAdmins: false,
                isEnabled: true
            ),
            AutoRule(
                name: "Rule 2: Severity Category",
                condition: .init(location: nil, category: "Fire/Safety Hazard", timeLimitHours: nil),
                setPriorityTo: .high,
                notifyAdmins: false,
                isEnabled: true
            ),
            AutoRule(
                name: "Rule 3: Service Level Agreement (SLA)",
                condition: .init(location: nil, category: nil, timeLimitHours: 4),
                setPriorityTo: .high,
                notifyAdmins: true,
                isEnabled: true
            )
        ]
    )
}

// MARK: - Storage



final class AutoRulesStore {
    private let key = "auto_rules_settings_v1"
    private let defaults = UserDefaults.standard

    func load() -> AutoRulesSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(AutoRulesSettings.self, from: data) else {
            return .default
        }
        return settings
    }

    func save(_ settings: AutoRulesSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        defaults.set(data, forKey: key)
    }

    func reset() {
        defaults.removeObject(forKey: key)
    }
}
