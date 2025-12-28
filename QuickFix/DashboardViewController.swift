//
//  DashboardViewController.swift
//  QuickFix
//
//  Dashboard cards ONLY (no image)
//

import UIKit

final class DashboardViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var pendingCardView: UIView!
    @IBOutlet weak var onProcessCardView: UIView!
    @IBOutlet weak var monthlyCardView: UIView!

    override func viewDidLoad() {
        super.viewDidLoad()
        styleCards()
    }

    // MARK: - UI
    private func styleCards() {
       

        applyCardStyle(pendingCardView)
        applyCardStyle(onProcessCardView)
        applyCardStyle(monthlyCardView)
    }

    private func applyCardStyle(_ v: UIView) {
        v.backgroundColor = .white
        v.layer.cornerRadius = 6
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.masksToBounds = true

        // ensure no shadow
        v.layer.shadowOpacity = 0
        v.layer.shadowRadius = 0
        v.layer.shadowOffset = .zero
        v.layer.shadowColor = nil
    }
}
