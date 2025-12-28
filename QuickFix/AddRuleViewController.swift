//
//  AddRuleViewController.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 25/12/2025.
//

import Foundation
import UIKit

// MARK: - Data you will send back to AutoRulesViewController
struct AutoPrioritizationRuleDraft {
    let name: String
    let location: String
    let category: String
    let timeLimitHours: Int
    let priority: String
    let notifyAdmins: Bool
    let isEnabled: Bool
}

protocol AddRuleViewControllerDelegate: AnyObject {
    func addRuleViewController(_ vc: AddRuleViewController, didCreate rule: AutoPrioritizationRuleDraft)
}

final class AddRuleViewController: UITableViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - Outlets
    @IBOutlet weak var locationPicker: UIPickerView!
    @IBOutlet weak var categoryPicker: UIPickerView!
    @IBOutlet weak var timeLimitPicker: UIPickerView!
    @IBOutlet weak var priorityPicker: UIPickerView!
    
    @IBOutlet weak var notifyAdminsSwitch: UISwitch!
    
    @IBOutlet weak var automaticSwitchOnSwitch: UISwitch!

    @IBOutlet weak var ruleNameTextField: UITextField!
    
    
    // MARK: - Delegate (AutoRules page will set this)
    weak var delegate: AddRuleViewControllerDelegate?
    
    // MARK: - Edit Mode
    private var editingRuleId: UUID? = nil
    private var pendingEditRule: AutoRule? = nil
    var currentEditingRuleId: UUID? { editingRuleId }

    // AutoRulesViewController بينادي هذي قبل ما يفتح الصفحة (وقت الـ Edit)
    func configureForEdit(rule: AutoRule) {
        editingRuleId = rule.id
        pendingEditRule = rule
    }
    
    // MARK: - Picker Data
    private var locations = ["Server Room", "Main Admin Office", "Workshop"]
    private var categories = ["Fire/Safety Hazard", "HVAC Emergency", "Electrical", "IT"]
    private var timeLimits = [1, 4, 8, 24]
    private let priorities = ["LOW", "MEDIUM", "HIGH", "URGENT"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCustomPickerItems()

        // tag لكل picker عشان نعرف أي واحد ينادي الداتا
        [locationPicker, categoryPicker, timeLimitPicker, priorityPicker].enumerated().forEach { i, picker in
            picker?.tag = i
            picker?.dataSource = self
            picker?.delegate = self
        }
        
        // اختيارات افتراضية (مهم لأن didSelectRow ما ينادي إذا المستخدم ما لفّ الـ picker)
        locationPicker.selectRow(0, inComponent: 0, animated: false)
        categoryPicker.selectRow(0, inComponent: 0, animated: false)
        timeLimitPicker.selectRow(0, inComponent: 0, animated: false)
        priorityPicker.selectRow(0, inComponent: 0, animated: false)
        
        applyPendingEditRuleIfNeeded()
    }
    
    private func applyPendingEditRuleIfNeeded() {
        guard let rule = pendingEditRule else { return }

        title = "Edit Rule"

        ruleNameTextField.text = rule.name
        notifyAdminsSwitch.isOn = rule.notifyAdmins
        automaticSwitchOnSwitch.isOn = rule.isEnabled

        // ✅ يخليها تشتغل سواء كانت Optional أو لا
        let loc: String? = rule.condition.location
        let cat: String? = rule.condition.category
        let tl: Int? = rule.condition.timeLimitHours

        if let loc, !locations.contains(loc) { locations.append(loc) }
        if let cat, !categories.contains(cat) { categories.append(cat) }
        if let tl, !timeLimits.contains(tl) { timeLimits.append(tl) }

        locations.sort()
        categories.sort()
        timeLimits.sort()

        locationPicker.reloadAllComponents()
        categoryPicker.reloadAllComponents()
        timeLimitPicker.reloadAllComponents()
        priorityPicker.reloadAllComponents()

        if let loc, let idx = locations.firstIndex(of: loc) {
            locationPicker.selectRow(idx, inComponent: 0, animated: false)
        }
        if let cat, let idx = categories.firstIndex(of: cat) {
            categoryPicker.selectRow(idx, inComponent: 0, animated: false)
        }
        if let tl, let idx = timeLimits.firstIndex(of: tl) {
            timeLimitPicker.selectRow(idx, inComponent: 0, animated: false)
        }

        // ✅ priority بدون rawValue (عشان ما يعطي error لو النوع مو enum)
        let raw = "\(rule.setPriorityTo)"
        let normalized = (raw.split(separator: ".").last.map(String.init) ?? raw).uppercased()

        if let idx = priorities.firstIndex(where: { $0.uppercased() == normalized }) {
            priorityPicker.selectRow(idx, inComponent: 0, animated: false)
        }
    }
    
    // MARK: - UIPickerViewDataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    } //  [oai_citation:2‡Apple Developer](https://developer.apple.com/documentation/uikit/uipickerviewdatasource/numberofcomponents%28in%3A%29?utm_source=chatgpt.com)
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        switch pickerView.tag {
        case 0: return locations.count
        case 1: return categories.count
        case 2: return timeLimits.count
        default: return priorities.count
        }
    } //  [oai_citation:3‡Apple Developer](https://developer.apple.com/documentation/uikit/uipickerviewdatasource/pickerview%28_%3Anumberofrowsincomponent%3A%29?utm_source=chatgpt.com)
    
    // MARK: - UIPickerViewDelegate
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        switch pickerView.tag {
        case 0: return locations[row]
        case 1: return categories[row]
        case 2: return "\(timeLimits[row]) hours"
        default: return priorities[row]
        }
    } //  [oai_citation:4‡Apple Developer](https://developer.apple.com/documentation/uikit/uipickerviewdelegate/pickerview%28_%3Atitleforrow%3Aforcomponent%3A%29?utm_source=chatgpt.com)
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        // إذا تبي لاحقًا تحدث Labels أو تلون UI حسب الاختيار، تسويه هنا
    } //  [oai_citation:5‡Apple Developer](https://developer.apple.com/documentation/uikit/uipickerviewdelegate/pickerview%28_%3Adidselectrow%3Aincomponent%3A%29?changes=_4)
    
    // MARK: - Save Action (connect your button here)
    @IBAction func saveRuleTapped(_ sender: UIButton) {
        
        view.endEditing(true)
        let name = (ruleNameTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            let alert = UIAlertController(
                title: "Missing Rule Name",
                message: "Please enter a name for the rule.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        let selectedLocation = locations[locationPicker.selectedRow(inComponent: 0)]
        let selectedCategory = categories[categoryPicker.selectedRow(inComponent: 0)]
        let selectedTimeLimit = timeLimits[timeLimitPicker.selectedRow(inComponent: 0)]
        let selectedPriority = priorities[priorityPicker.selectedRow(inComponent: 0)]
        
        let store = AutoRulesStore()
        var settings = store.load()

        let condition = AutoRuleCondition(
            location: selectedLocation,
            category: selectedCategory,
            timeLimitHours: selectedTimeLimit
        )

        let ruleId = editingRuleId ?? UUID()

        guard let priorityLevel = PriorityLevel(rawValue: selectedPriority) else {
            return
        }

        let newRule = AutoRule(
            id: ruleId,
            name: name,
            condition: condition,
            setPriorityTo: priorityLevel,
            notifyAdmins: notifyAdminsSwitch.isOn,
            isEnabled: automaticSwitchOnSwitch.isOn
        )

        if let editId = editingRuleId,
           let idx = settings.rules.firstIndex(where: { $0.id == editId }) {
            settings.rules[idx] = newRule
        } else {
            settings.rules.append(newRule)
        }

        store.save(settings)
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Keys for saving custom items
    private let kCustomLocations = "custom_locations_v1"
    private let kCustomCategories = "custom_categories_v1"
    private let kCustomTimeLimits = "custom_timelimits_v1"

    // Call this in viewDidLoad() at the top
    private func loadCustomPickerItems() {
        let defaults = UserDefaults.standard

        if let saved = defaults.array(forKey: kCustomLocations) as? [String] {
            locations.append(contentsOf: saved)
        }
        if let saved = defaults.array(forKey: kCustomCategories) as? [String] {
            categories.append(contentsOf: saved)
        }
        if let saved = defaults.array(forKey: kCustomTimeLimits) as? [Int] {
            timeLimits.append(contentsOf: saved)
        }

        // Remove duplicates (simple)
        locations = Array(Set(locations)).sorted()
        categories = Array(Set(categories)).sorted()
        timeLimits = Array(Set(timeLimits)).sorted()
    }

    private func saveCustomLocations(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: kCustomLocations)
    }

    private func saveCustomCategories(_ items: [String]) {
        UserDefaults.standard.set(items, forKey: kCustomCategories)
    }

    private func saveCustomTimeLimits(_ items: [Int]) {
        UserDefaults.standard.set(items, forKey: kCustomTimeLimits)
    }

    @IBAction func addLocationTapped(_ sender: UIButton) {
        promptForNewString(title: "Add Location", message: "Type a new location") { newValue in
            let value = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }

            // prevent duplicates (case-insensitive)
            if self.locations.contains(where: { $0.lowercased() == value.lowercased() }) { return }

            self.locations.append(value)
            self.locations.sort()

            // reload + select
            self.locationPicker.reloadAllComponents()
            if let idx = self.locations.firstIndex(of: value) {
                self.locationPicker.selectRow(idx, inComponent: 0, animated: true)
            }

            // persist only custom-added items (optional: store all, or store extras only)
            self.saveCustomLocations(self.locations)
        }
    }

    @IBAction func addCategoryTapped(_ sender: UIButton) {
        promptForNewString(title: "Add Category", message: "Type a new category") { newValue in
            let value = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !value.isEmpty else { return }
            if self.categories.contains(where: { $0.lowercased() == value.lowercased() }) { return }

            self.categories.append(value)
            self.categories.sort()

            self.categoryPicker.reloadAllComponents()
            if let idx = self.categories.firstIndex(of: value) {
                self.categoryPicker.selectRow(idx, inComponent: 0, animated: true)
            }

            self.saveCustomCategories(self.categories)
        }
    }

    @IBAction func addTimeLimitTapped(_ sender: UIButton) {
        promptForNewString(title: "Add Time Limit (hours)", message: "Example: 6") { newValue in
            let trimmed = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let hours = Int(trimmed), hours > 0 else { return }

            if self.timeLimits.contains(hours) { return }

            self.timeLimits.append(hours)
            self.timeLimits.sort()

            self.timeLimitPicker.reloadAllComponents()
            if let idx = self.timeLimits.firstIndex(of: hours) {
                self.timeLimitPicker.selectRow(idx, inComponent: 0, animated: true)
            }

            self.saveCustomTimeLimits(self.timeLimits)
        }
    }

    // Helper: Alert with a TextField
    private func promptForNewString(title: String, message: String, onAdd: @escaping (String) -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addTextField { tf in
            tf.placeholder = "New value"
        }
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Add", style: .default) { _ in
            let text = alert.textFields?.first?.text ?? ""
            onAdd(text)
        })
        present(alert, animated: true)
    }
    
}
