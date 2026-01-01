//
//  NotificationsViewController.swift
//  QuickFix
//
//  Created by Ali Alsaeed on 29/12/2025.
//

import UIKit

final class NotificationsViewController: UITableViewController {

    private let store = NotificationStore()
    
    private enum FilterMode: Int { case all, unread, unseen, system }
    private var filter: FilterMode = .all


    var audience: NotificationAudience = .user

    private var allItems: [AppNotification] = []
    private var items: [AppNotification] = []

    private let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        store.add(AppNotification(
            id: UUID(),
            audience: .user,
            category: .statusUpdate,
            title: "Status Update",
            message: "Ticket #052 is now In Progress",
            createdAt: Date().addingTimeInterval(-5 * 60),
            isRead: false,
            isSeen: false,
            ticketId: nil
        ))

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 90

        if let header = tableView.tableHeaderView,
           let seg = header.viewWithTag(400) as? UISegmentedControl {

            seg.removeAllSegments()

            if audience == .admin {
                seg.insertSegment(withTitle: "All", at: 0, animated: false)
                seg.insertSegment(withTitle: "System Alerts", at: 1, animated: false)
                seg.selectedSegmentIndex = 0
                filter = .all
            } else {
                seg.insertSegment(withTitle: "All", at: 0, animated: false)
                seg.insertSegment(withTitle: "Unread", at: 1, animated: false)
                seg.insertSegment(withTitle: "Unseen", at: 2, animated: false)
                seg.selectedSegmentIndex = 0
                filter = .all
            }

            seg.addTarget(self, action: #selector(filterChanged(_:)), for: .valueChanged)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        store.markAllSeen(for: audience)

        reloadData()
    }

    private func reloadData() {
        allItems = store.load().filter { $0.audience == audience }
        applyFilter()
    }

    private func applyFilter() {
        switch filter {
        case .all:
            items = allItems
        case .unread:
            items = allItems.filter { !$0.isRead }
        case .unseen:
            items = allItems.filter { !$0.isSeen }
        case .system:
            items = allItems.filter { $0.category == .systemAlert || $0.category == .overdueAlert }
        }
        tableView.reloadData()
    }

    @objc private func filterChanged(_ sender: UISegmentedControl) {
        if audience == .admin {
            filter = (sender.selectedSegmentIndex == 1) ? .system : .all
        } else {
            switch sender.selectedSegmentIndex {
            case 1: filter = .unread
            case 2: filter = .unseen
            default: filter = .all
            }
        }
        applyFilter()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationCell", for: indexPath)
        let n = items[indexPath.row]

        if let bar = cell.viewWithTag(401) as? UIView {
            let isSystemAlert = (n.category == .systemAlert || n.category == .overdueAlert)
            bar.backgroundColor = isSystemAlert ? .systemRed : .systemBlue
            bar.layer.cornerRadius = 1.5
        }

        if let typeLabel = cell.viewWithTag(402) as? UILabel {
            typeLabel.text = {
                switch n.category {
                case .overdueAlert: return "OVERDUE ALERT"
                case .assignment: return "NEW ASSIGNMENT"
                case .statusUpdate: return "STATUS UPDATE"
                case .systemAlert: return "SYSTEM ALERT"
                }
            }()
            let isSystemAlert = (n.category == .systemAlert || n.category == .overdueAlert)
            typeLabel.textColor = isSystemAlert ? .systemRed : .label
        }

        if let titleLabel = cell.viewWithTag(403) as? UILabel {
            titleLabel.text = n.title
            titleLabel.numberOfLines = 0
        }

        if let timeLabel = cell.viewWithTag(404) as? UILabel {
            timeLabel.text = relativeFormatter.localizedString(for: n.createdAt, relativeTo: Date())
        }

        if let btn = cell.viewWithTag(405) as? UIButton {
            btn.accessibilityIdentifier = n.id.uuidString
            btn.removeTarget(nil, action: nil, for: .touchUpInside)
            btn.addTarget(self, action: #selector(showTapped(_:)), for: .touchUpInside)
        }

        cell.contentView.alpha = n.isRead ? 0.6 : 1.0

        return cell
    }

    @objc private func showTapped(_ sender: UIButton) {
        guard let idStr = sender.accessibilityIdentifier,
              let id = UUID(uuidString: idStr),
              let n = allItems.first(where: { $0.id == id }) else { return }

        store.markRead(id: id)
        reloadData()

        print("Show notification:", n.title)
    }
}
