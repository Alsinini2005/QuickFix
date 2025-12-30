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
    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        guard let sec = Section(rawValue: section) else { return 0 }
        if sec == .rules { return 16 }  // مسافة قبل زر Add
        return 0.01
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = store.load()
        tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
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

            // Title Label (Tag 201)
            if let titleLabel = cell.viewWithTag(201) as? UILabel {
                titleLabel.text = "Rule \(indexPath.row + 1): \(cleanRuleName(rule.name))"
            }

            // Subtitle Label (Tag 202)
            if let subtitleLabel = cell.viewWithTag(202) as? UILabel {
                subtitleLabel.text = ruleSummary(rule)
                subtitleLabel.numberOfLines = 0
                subtitleLabel.lineBreakMode = .byWordWrapping
            }

            // Switch (Tag 203)
            if let sw = cell.viewWithTag(203) as? UISwitch {
                sw.isOn = rule.isEnabled
                sw.accessibilityIdentifier = rule.id.uuidString
                sw.removeTarget(nil, action: nil, for: .valueChanged)
                sw.addTarget(self, action: #selector(ruleEnabledChanged(_:)), for: .valueChanged)
            }
            return cell
            

        case .addButton:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddButtonCell", for: indexPath)
            return cell
        }
    }
    
    private func cleanRuleName(_ name: String) -> String {
        let t = name.trimmingCharacters(in: .whitespacesAndNewlines)
        // إذا الاسم القديم كان مكتوب "Rule 1: شيء"
        if t.lowercased().hasPrefix("rule"), let r = t.range(of: ":") {
            return t[r.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return t
    }
    private func makeRuleAccessoryView(ruleId: UUID, isOn: Bool) -> UIView {
        let sw = UISwitch()
        sw.isOn = isOn
        sw.accessibilityIdentifier = ruleId.uuidString

        sw.removeTarget(nil, action: nil, for: .valueChanged)
        sw.addTarget(self, action: #selector(ruleEnabledChanged(_:)), for: .valueChanged)

        let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
        chevron.tintColor = .tertiaryLabel

        let stack = UIStackView(arrangedSubviews: [sw, chevron])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10

        return stack
    }
    
    private func ruleSummary(_ rule: AutoRule) -> String {
        let loc = rule.condition.location ?? "Any location"
        let cat = rule.condition.category ?? "Any category"
        let time = rule.condition.timeLimitHours != nil ? "\(rule.condition.timeLimitHours!)h" : "Any time"
        return "If \(loc) • \(cat) • \(time) → \(rule.setPriorityTo.rawValue)"
    }
    
    @objc private func ruleEnabledChanged(_ sender: UISwitch) {
        guard
            let idString = sender.accessibilityIdentifier,
            let id = UUID(uuidString: idString)
        else { return }

        settings = store.load()

        guard let idx = settings.rules.firstIndex(where: { $0.id == id }) else { return }
        settings.rules[idx].isEnabled = sender.isOn

        store.save(settings)

        // تحديث سريع للسطر
        tableView.reloadRows(at: [IndexPath(row: idx, section: Section.rules.rawValue)], with: .none)
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
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return Section(rawValue: indexPath.section) == .rules
    }
    override func tableView(_ tableView: UITableView,
                            trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard Section(rawValue: indexPath.section) == .rules else { return nil }

        let delete = UIContextualAction(style: .destructive, title: "Delete") { [weak self] _, _, completion in
            guard let self = self else { completion(false); return }

            // خذ آخر نسخة
            self.settings = self.store.load()

            // حماية إذا تغيّر العدد
            guard indexPath.row < self.settings.rules.count else { completion(false); return }

            // احذف + احفظ
            self.settings.rules.remove(at: indexPath.row)
            self.store.save(self.settings)

            // حدّث الجدول
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        }

        return UISwipeActionsConfiguration(actions: [delete])
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        let dest = segue.destination
        let addVC =
            (dest as? UINavigationController)?.topViewController as? AddRuleViewController
            ?? dest as? AddRuleViewController

        guard let vc = addVC else { return }

        if segue.identifier == "AddRuleSegue" {
            vc.delegate = self
        }

        if segue.identifier == "EditRuleSegue" {
            vc.delegate = self
            if let rule = sender as? AutoRule {
                vc.configureForEdit(rule: rule)
            }
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
