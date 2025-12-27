//
//  TicketDetailsVeiwController.swift
//  QuickFix
//
//  Created by BP-36-212-02 on 25/12/2025.
//

import Foundation
import UIKit

final class TicketDetailsViewController: UIViewController {

    // MARK: - Outlets (connect these)
    @IBOutlet private weak var containerView: UIView!   // wrap the stack view in a UIView
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var imageTitleLabel: UILabel!
    @IBOutlet private weak var ticketImageView: UIImageView!

    @IBOutlet private weak var assignButton: UIButton!

    // Value labels (right side)
    @IBOutlet private weak var ticketIdLabel: UILabel!
    @IBOutlet private weak var ticketNameLabel: UILabel!
    @IBOutlet private weak var campusLabel: UILabel!
    @IBOutlet private weak var buildingLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!
    @IBOutlet private weak var urgencyLabel: UILabel!

    // Title labels (left side)
    @IBOutlet private weak var ticketIdTitle: UILabel!
    @IBOutlet private weak var ticketNameTitle: UILabel!
    @IBOutlet private weak var campusTitle: UILabel!
    @IBOutlet private weak var buildingTitle: UILabel!
    @IBOutlet private weak var statusTitle: UILabel!
    @IBOutlet private weak var createdTitle: UILabel!
    @IBOutlet private weak var urgencyTitle: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        styleScreen()
    }

    // MARK: - Navigation Bar
    private func setupNavBar() {
        title = "Ticket Details"

        let barColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)

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
    }

    // MARK: - Styling
    private func styleScreen() {
        view.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)

        // Card
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true

        // Stack view
        stackView.spacing = 0
        addSeparators()

        // Left titles
        let titleLabels = [
            ticketIdTitle, ticketNameTitle, campusTitle,
            buildingTitle, statusTitle, urgencyTitle, createdTitle
        ]

        titleLabels.forEach {
            $0?.font = .systemFont(ofSize: 13, weight: .semibold)
            $0?.textColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        }

        // Right values
        let valueLabels = [
            ticketIdLabel, ticketNameLabel, campusLabel,
            buildingLabel, statusLabel, urgencyLabel, createdLabel
        ]

        valueLabels.forEach {
            $0?.font = .systemFont(ofSize: 13)
            $0?.textColor = .secondaryLabel
        }

        // Image section
        imageTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        imageTitleLabel.textColor = .label

        ticketImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        ticketImageView.layer.cornerRadius = 12
        ticketImageView.layer.masksToBounds = true
        ticketImageView.contentMode = .scaleAspectFill

        // Assign button
        assignButton.backgroundColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        assignButton.setTitleColor(.white, for: .normal)
        assignButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        assignButton.layer.cornerRadius = 10
    }

    // MARK: - Separators between rows
    private func addSeparators() {
        for (index, row) in stackView.arrangedSubviews.enumerated() {
            guard index != stackView.arrangedSubviews.count - 1 else { continue }

            let separator = UIView()
            separator.backgroundColor = UIColor.systemGray5
            separator.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(separator)

            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
    }
}
