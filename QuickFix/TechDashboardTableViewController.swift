//
//  TechDashboardTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 28/12/2025.
//

import UIKit

final class TechDashboardTableViewController: UITableViewController {

    // MARK: - Bar chart storage
    private var barHeightConstraints: [NSLayoutConstraint] = []
    private var chartBuilt = false

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
    }

    // MARK: - TableView
    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {

        // Apply border to all container views
        applyBorderToAllViews(in: cell.contentView)

        // 🔴 CHANGE THIS ROW INDEX if your chart is not row 3
        if indexPath.row == 3 {
            buildBarChartIfNeeded(in: cell.contentView)
            updateBarValues([20, 50, 35, 80])   // Week 1 → Week 4
        }
    }

    // MARK: - Border helper
    private func applyBorderToAllViews(in rootView: UIView) {
        for subview in rootView.subviews {

            // Skip text-based views
            if subview is UILabel ||
               subview is UIImageView ||
               subview is UIButton ||
               subview is UITextField ||
               subview is UITextView {

                applyBorderToAllViews(in: subview)
                continue
            }

            subview.layer.cornerRadius = 12
            subview.layer.borderWidth = 1
            subview.layer.borderColor = UIColor.systemGray5.cgColor
            subview.backgroundColor = .systemBackground
            subview.clipsToBounds = true

            applyBorderToAllViews(in: subview)
        }
    }
}

// MARK: - Bar Chart (100% Code)
extension TechDashboardTableViewController {

    func buildBarChartIfNeeded(in rootView: UIView) {
        guard chartBuilt == false else { return }

        // Find the chart container
        guard let chartContainer = rootView.viewWithTag(999) else {
            print("❌ Chart container not found. Set tag = 999.")
            return
        }

        chartBuilt = true
        chartContainer.subviews.forEach { $0.removeFromSuperview() }
        barHeightConstraints.removeAll()

        let barWidth: CGFloat = 22
        let spacing: CGFloat = 26
        let bottomPadding: CGFloat = 28
        let weeks = ["Week 1", "Week 2", "Week 3", "Week 4"]

        var previousBar: UIView?

        for i in 0..<4 {

            // Bar
            let bar = UIView()
            bar.translatesAutoresizingMaskIntoConstraints = false
            bar.backgroundColor = .systemGray4
            bar.layer.cornerRadius = 8
            bar.clipsToBounds = true
            chartContainer.addSubview(bar)

            let heightConstraint = bar.heightAnchor.constraint(equalToConstant: 40)
            barHeightConstraints.append(heightConstraint)

            NSLayoutConstraint.activate([
                bar.bottomAnchor.constraint(equalTo: chartContainer.bottomAnchor,
                                            constant: -bottomPadding),
                bar.widthAnchor.constraint(equalToConstant: barWidth),
                heightConstraint
            ])

            if let prev = previousBar {
                bar.leadingAnchor.constraint(equalTo: prev.trailingAnchor,
                                             constant: spacing).isActive = true
            } else {
                bar.leadingAnchor.constraint(equalTo: chartContainer.leadingAnchor,
                                             constant: 24).isActive = true
            }

            // Label
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.text = weeks[i]
            label.font = .systemFont(ofSize: 13, weight: .medium)
            label.textColor = .secondaryLabel
            label.textAlignment = .center
            chartContainer.addSubview(label)

            NSLayoutConstraint.activate([
                label.topAnchor.constraint(equalTo: bar.bottomAnchor, constant: 8),
                label.centerXAnchor.constraint(equalTo: bar.centerXAnchor)
            ])

            previousBar = bar
        }
    }

    func updateBarValues(_ values: [CGFloat]) {
        guard barHeightConstraints.count == 4 else { return }

        let maxValue = max(values.max() ?? 1, 1)
        let maxHeight: CGFloat = 140

        for i in 0..<4 {
            let v = i < values.count ? values[i] : 0
            barHeightConstraints[i].constant = max(6, (v / maxValue) * maxHeight)
        }

        UIView.animate(withDuration: 0.25) {
            self.tableView.layoutIfNeeded()
        }
    }
}


