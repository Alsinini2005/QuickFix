//
//  TaskListViewController.swift
//  QuickFix
//
//  Created by BP-36-212-02 on 25/12/2025.
//

import Foundation

import UIKit

// Paste this file as your TaskListViewController.swift
// Storyboard requirements:
// 1) Your VC class = TaskListViewController
// 2) Connect the tableView outlet
// 3) In the prototype cell: Identifier = "TaskCell", Style = "Subtitle"

final class TaskListViewController: UIViewController {

    @IBOutlet private weak var tableView: UITableView!

    // MARK: - Demo data (replace with your real data)
    enum TaskStatus: String {
        case pending = "Pending"
        case inProgress = "In Progress"
        case completed = "Completed"
    }

    struct TaskItem {
        let title: String
        let submitted: String
        let status: TaskStatus
        let showChevron: Bool
    }

    private var tasks: [TaskItem] = [
        .init(title: "Wi-Fi not connecting in library", submitted: "Oct 26, 2023", status: .pending, showChevron: false),
        .init(title: "Projector bulb is out in Room 201", submitted: "Oct 24, 2023", status: .inProgress, showChevron: false),
        .init(title: "Cannot log in to the student portal", submitted: "Oct 22, 2023", status: .completed, showChevron: true),
        .init(title: "Wi-Fi not connecting in web media Building", submitted: "Oct 26, 2023", status: .pending, showChevron: true),
        .init(title: "Smart board isn’t working on Room 201", submitted: "Oct 24, 2023", status: .inProgress, showChevron: true)
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        setupTable()
    }

    // MARK: - UI

    private func setupNavBar() {
        title = "Task List"

        // Dark bar like screenshot
        let barColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        navigationController?.navigationBar.isTranslucent = false

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barColor
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        // If you want the back arrow shown, DO NOT hide it.
        // If you want a custom back button uncomment below:
        /*
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(didTapBack)
        )
        */
    }

    @objc private func didTapBack() {
        navigationController?.popViewController(animated: true)
    }

    private func setupTable() {
        view.backgroundColor = .systemGroupedBackground

        tableView.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)

        tableView.dataSource = self
        tableView.delegate = self

        // If storyboard cell isn't registered, fallback register
        if tableView.dequeueReusableCell(withIdentifier: "TaskCell") == nil {
            tableView.register(UITableViewCell.self, forCellReuseIdentifier: "TaskCell")
        }
    }

    // MARK: - Helpers

    private func statusConfig(for status: TaskStatus) -> (title: String, bg: UIColor, text: UIColor, dot: UIColor) {
        switch status {
        case .pending:
            let dot = UIColor(red: 241/255, green: 90/255, blue: 90/255, alpha: 1)
            return ("Pending",
                    UIColor(red: 1, green: 0.93, blue: 0.93, alpha: 1),
                    dot,
                    dot)
        case .inProgress:
            let dot = UIColor(red: 225/255, green: 169/255, blue: 40/255, alpha: 1)
            return ("In Progress",
                    UIColor(red: 1, green: 0.96, blue: 0.86, alpha: 1),
                    dot,
                    dot)
        case .completed:
            let dot = UIColor(red: 55/255, green: 171/255, blue: 97/255, alpha: 1)
            return ("Completed",
                    UIColor(red: 0.88, green: 0.98, blue: 0.91, alpha: 1),
                    dot,
                    dot)
        }
    }

    private func makeStatusBadge(status: TaskStatus) -> UIView {
        let cfg = statusConfig(for: status)

        let container = UIView()
        container.backgroundColor = cfg.bg
        container.layer.cornerRadius = 10
        container.layer.masksToBounds = true

        let dot = UIView()
        dot.backgroundColor = cfg.dot
        dot.layer.cornerRadius = 3

        let label = UILabel()
        label.text = cfg.title
        label.textColor = cfg.text
        label.font = .systemFont(ofSize: 12, weight: .semibold)

        container.addSubview(dot)
        container.addSubview(label)

        dot.translatesAutoresizingMaskIntoConstraints = false
        label.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            dot.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 10),
            dot.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            dot.widthAnchor.constraint(equalToConstant: 6),
            dot.heightAnchor.constraint(equalToConstant: 6),

            label.leadingAnchor.constraint(equalTo: dot.trailingAnchor, constant: 6),
            label.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -10),
            label.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])

        return container
    }

    private func applyCardStyle(to cell: UITableViewCell) {
        cell.backgroundColor = .clear
        cell.selectionStyle = .none

        // Card container
        cell.contentView.backgroundColor = .white
        cell.contentView.layer.cornerRadius = 12
        cell.contentView.layer.masksToBounds = true
        cell.contentView.layer.borderWidth = 0
        cell.contentView.layer.borderColor = UIColor.clear.cgColor
    }
}

// MARK: - UITableViewDataSource
extension TaskListViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tasks.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Use storyboard cell "Subtitle" style
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCell", for: indexPath)

        let item = tasks[indexPath.row]

        // Basic labels
        cell.textLabel?.text = item.title
        cell.textLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
        cell.textLabel?.textColor = .label
        cell.textLabel?.numberOfLines = 2

        cell.detailTextLabel?.text = "Submitted: \(item.submitted)"
        cell.detailTextLabel?.font = .systemFont(ofSize: 12, weight: .regular)
        cell.detailTextLabel?.textColor = .secondaryLabel

        // Chevron like screenshot (some rows only)
        cell.accessoryType = item.showChevron ? .disclosureIndicator : .none

        // Card style
        applyCardStyle(to: cell)

        // Add status badge under subtitle (reuse-safe)
        let badgeTag = 9001
        cell.contentView.viewWithTag(badgeTag)?.removeFromSuperview()

        let badge = makeStatusBadge(status: item.status)
        badge.tag = badgeTag
        cell.contentView.addSubview(badge)

        badge.translatesAutoresizingMaskIntoConstraints = false

        // Place badge at bottom-left inside card
        NSLayoutConstraint.activate([
            badge.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            badge.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -12)
        ])

        // Extra bottom padding so badge doesn't overlap labels
        // (We’ll push the default labels up by adding insets via layoutMargins)
        cell.contentView.layoutMargins = UIEdgeInsets(top: 14, left: 16, bottom: 38, right: 16)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension TaskListViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        110
    }

    func tableView(_ tableView: UITableView,
                   willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {

        // Create spacing between cards by insetting the contentView frame
        let horizontal: CGFloat = 16
        let vertical: CGFloat = 10
        let frame = cell.contentView.frame
        cell.contentView.frame = frame.inset(by: UIEdgeInsets(top: vertical, left: horizontal, bottom: vertical, right: horizontal))
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // navigate if needed
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
