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
    private var settings: AutoRulesSettings!
    private var selectedRuleIndexForEdit: Int?


    @IBOutlet weak var manualOverrideSwitch: UISwitch!

    @IBOutlet weak var rule1Switch: UISwitch!
    @IBOutlet weak var rule2Switch: UISwitch!
    @IBOutlet weak var rule3Switch: UISwitch!

    override func viewDidLoad() {
        super.viewDidLoad()

        // عشان نعرف أي سويتش يمثل أي Rule
        rule1Switch.tag = 0
        rule2Switch.tag = 1
        rule3Switch.tag = 2
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        settings = store.load()
        tableView.reloadData()
    }
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        
        guard indexPath.section == 1 else { return }

        let ruleIndex = indexPath.row
        guard ruleIndex < settings.rules.count else { return }

        selectedRuleIndexForEdit = ruleIndex
        performSegue(withIdentifier: "EditRuleSegue", sender: self)
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard segue.identifier == "EditRuleSegue" else { return }
        guard let ruleIndex = selectedRuleIndexForEdit, ruleIndex < settings.rules.count else { return }

        let rule = settings.rules[ruleIndex]

        if let editVC = segue.destination as? AddRuleViewController {
            editVC.configureForEdit(rule: rule)
        } else if let nav = segue.destination as? UINavigationController,
                  let editVC = nav.viewControllers.first as? AddRuleViewController {
            editVC.configureForEdit(rule: rule)
        }
    }

    private func loadAndRender() {
        settings = store.load()

        manualOverrideSwitch.isOn = settings.manualOverrideAllowed

        let ruleSwitches: [UISwitch] = [rule1Switch, rule2Switch, rule3Switch]
        for (i, sw) in ruleSwitches.enumerated() {
            if i < settings.rules.count {
                sw.isHidden = false
                sw.isOn = settings.rules[i].isEnabled
            } else {
                sw.isHidden = true
            }
        }
    }

    @IBAction func manualOverrideChanged(_ sender: UISwitch) {
        settings.manualOverrideAllowed = sender.isOn
        store.save(settings)
    }

    @IBAction func ruleSwitchChanged(_ sender: UISwitch) {
        let index = sender.tag
        guard index < settings.rules.count else { return }

        settings.rules[index].isEnabled = sender.isOn
        store.save(settings)
    }
}
