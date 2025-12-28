//
//  AutoRulesViewController.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 25/12/2025.
//

import Foundation
import UIKit

final class AutoRulesViewController: UITableViewController {

    private let store = AutoRulesStore()
    private var settings: AutoRulesSettings = .default

    enum Section: Int, CaseIterable {
        case manualOverride = 0
        case rules = 1
        case addButton = 2
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = store.load()
        tableView.reloadData()
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        Section.allCases.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard let sec = Section(rawValue: section) else { return 0 }
        switch sec {
        case .manualOverride: return 1
        case .rules: return settings.rules.count
        case .addButton: return 1
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let sec = Section(rawValue: indexPath.section) else { return UITableViewCell() }

        switch sec {

        case .manualOverride:
            let cell = tableView.dequeueReusableCell(withIdentifier: "ManualOverrideCell", for: indexPath)


            if let sw = cell.viewWithTag(100) as? UISwitch {
                sw.isOn = settings.manualOverrideAllowed
                sw.addTarget(self, action: #selector(manualOverrideChanged(_:)), for: .valueChanged)
            }
            return cell

        case .rules:
            let cell = tableView.dequeueReusableCell(withIdentifier: "RuleCell", for: indexPath)
            let rule = settings.rules[indexPath.row]

            cell.textLabel?.text = rule.name
            cell.detailTextLabel?.text = ruleSummary(rule)   // وصف تحت
            cell.accessoryType = .disclosureIndicator
            return cell

        case .addButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddButtonCell", for: indexPath)
            return cell
        }
    }

    private func ruleSummary(_ rule: AutoRule) -> String {
        // غيّر حسب موديلك
        let loc = rule.condition.location ?? "Any location"
        let cat = rule.condition.category ?? "Any category"
        let time = rule.condition.timeLimitHours != nil ? "\(rule.condition.timeLimitHours!)h" : "Any time"
        return "If \(loc) • \(cat) • \(time) → \(rule.setPriorityTo.rawValue)"
    }

    @objc private func manualOverrideChanged(_ sender: UISwitch) {
        settings.manualOverrideAllowed = sender.isOn
        store.save(settings)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let sec = Section(rawValue: indexPath.section) else { return }
        tableView.deselectRow(at: indexPath, animated: true)

        switch sec {
        case .rules:
            let rule = settings.rules[indexPath.row]
            performSegue(withIdentifier: "EditRuleSegue", sender: rule)

        case .addButton:
            performSegue(withIdentifier: "AddRuleSegue", sender: nil)

        default:
            break
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddRuleSegue" {
            let vc = segue.destination as! AddRuleViewController
            vc.delegate = self

        }

        if segue.identifier == "EditRuleSegue" {
            let vc = segue.destination as! AddRuleViewController
            vc.delegate = self

            if let rule = sender as? AutoRule {
                vc.configureForEdit(rule: rule)
                // أو vc.mode = .edit(existing: rule)
            }
        }
    }
    
    extension AutoRulesViewController: AddRuleViewControllerDelegate {

        func addRuleViewController(_ vc: AddRuleViewController, didCreate draft: AutoPrioritizationRuleDraft) {

            // 1) load latest (عشان ما نكتب فوق نسخة قديمة)
            settings = store.load()

            // 2) حوّل priority string إلى PriorityLevel
            guard let level = PriorityLevel(rawValue: draft.priority) else {
                // لو صار mismatch بين نصوص priorities عندك و enum
                return
            }

            // 3) سو AutoRuleCondition
            let condition = AutoRuleCondition(
                location: draft.location,
                category: draft.category,
                timeLimitHours: draft.timeLimitHours
            )

            // 4) هل هذا Add ولا Edit؟
            // لازم AddRuleViewController ترسل لنا ID إذا edit (راح نسويها بالخطوة C)
            if let editingId = vc.currentEditingRuleId {
                // EDIT
                if let idx = settings.rules.firstIndex(where: { $0.id == editingId }) {
                    settings.rules[idx].name = draft.name
                    settings.rules[idx].condition = condition
                    settings.rules[idx].setPriorityTo = level
                    settings.rules[idx].notifyAdmins = draft.notifyAdmins
                    settings.rules[idx].isEnabled = draft.isEnabled
                }
            } else {
                // ADD
                let newRule = AutoRule(
                    id: UUID(),
                    name: draft.name,
                    condition: condition,
                    setPriorityTo: level,
                    notifyAdmins: draft.notifyAdmins,
                    isEnabled: draft.isEnabled
                )
                settings.rules.append(newRule)
            }

            // 5) Save + refresh
            store.save(settings)
            tableView.reloadData()
        }
    }
}
