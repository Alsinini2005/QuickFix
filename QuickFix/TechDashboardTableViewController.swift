//
//  TechDashboardTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 28/12/2025.
//

import UIKit

final class TechDashboardTableViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {

        applyBorderToAllViews(in: cell.contentView)
        
        if indexPath.row == 3 {
            updateBars(in: cell, values: [20, 50, 35, 80])
        }
    }

    private func updateBars(in cell: UITableViewCell, values: [CGFloat]) {
        let maxBarHeight: CGFloat = 160 
        let maxValue = values.max() ?? 1

        let tags = [101, 102, 103, 104]

        for (i, tag) in tags.enumerated() {
            guard i < values.count,
                  let bar = cell.contentView.viewWithTag(tag) else { continue }

            if let heightConstraint = bar.constraints.first(where: { $0.firstAttribute == .height }) {
                heightConstraint.constant = (values[i] / maxValue) * maxBarHeight
            }
        }

        UIView.animate(withDuration: 0.3) {
            cell.layoutIfNeeded()
        }
    }

    private func applyBorderToAllViews(in rootView: UIView) {
        for subview in rootView.subviews {

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


