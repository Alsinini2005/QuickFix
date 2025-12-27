//
//  ReportViewController.swift
//  QuickFix
//
//  Created by BP-36-212-02 on 25/12/2025.
//

import Foundation
import UIKit

final class ReportViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Demo data (replace with your real data)
    private let monthlyReports: [(title: String, created: String)] = [
        ("April - 2023 monthly report", "May 2, 2023"),
        ("March - 2023 monthly report", "April 2, 2023")
    ]

    private let yearlyReports: [(title: String, created: String)] = [
        ("2022 yearly report", "Jan 6, 2023")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.backgroundColor = .systemGroupedBackground

        // Table styling
        tableView.backgroundColor = .systemGroupedBackground
        tableView.separatorStyle = .none
        tableView.sectionHeaderTopPadding = 16
        tableView.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 24, right: 0)

        // Delegates
        tableView.dataSource = self
        tableView.delegate = self

        // If your storyboard cell identifier is different, change it here
        // In Storyboard: select the prototype cell -> Identifier = "ReportCell"
        if tableView.dequeueReusableCell(withIdentifier: "ReportCell") == nil {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ReportCell")
        }

        // Optional: nav title
        navigationItem.title = "Tech report record"
    }
}

// MARK: - UITableViewDataSource
extension ReportViewController: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int { 2 }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        section == 0 ? monthlyReports.count : yearlyReports.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "ReportCell", for: indexPath)

        // Clear default styles
        cell.selectionStyle = .default
        cell.backgroundColor = .clear
        cell.contentView.backgroundColor = .white

        // Data
        let item = (indexPath.section == 0) ? monthlyReports[indexPath.row] : yearlyReports[indexPath.row]

        // Use built-in "subtitle" style if possible
        // If your prototype cell is "Basic", switch it to "Subtitle" in storyboard
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.textColor = .label

        cell.detailTextLabel?.text = "Created: \(item.created)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel

        // Accessory like screenshot (chevron)
        cell.accessoryType = .disclosureIndicator

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ReportViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        72
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        // Card styling (rounded + border)
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.borderWidth = 1
        cell.contentView.layer.borderColor = UIColor.systemGray5.cgColor

        // Spacing around the card (important)
        let horizontal: CGFloat = 16
        let vertical: CGFloat = 8

        // Inset the contentView frame to create spacing
        let frame = cell.contentView.frame
        cell.contentView.frame = frame.inset(by: UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal))
    }

    func tableView(_ tableView: UITableView,
                   viewForHeaderInSection section: Int) -> UIView? {

        let container = UIView()
        container.backgroundColor = .clear

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = (section == 0) ? "Monthly Report" : "Yearly Report"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = .label

        container.addSubview(label)

        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 16),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -6)
        ])

        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        48
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        // Handle navigation if you want
    }
}
