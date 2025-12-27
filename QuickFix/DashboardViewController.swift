//
//  DashboardViewController.swift
//  QuickFix
//
//  Created by BP-36-212-02 on 25/12/2025.
//

import Foundation

import UIKit

final class DashboardViewController: UIViewController {

    @IBOutlet weak var pendingCardView: UIView!
    
    @IBOutlet weak var onProcessCardView: UIView!
    
    @IBOutlet weak var monthlyCardView: UIView!
    

    override func viewDidLoad() {
        super.viewDidLoad()
        styleCards()
    }

    private func styleCards() {
        // screen background like the screenshot
        view.backgroundColor = .systemBackground

        // small cards
        applyCardStyle(pendingCardView)
        applyCardStyle(onProcessCardView)

        // big card (same style)
        applyCardStyle(monthlyCardView)
    }

    private func applyCardStyle(_ v: UIView) {
        v.backgroundColor = .white
        v.layer.cornerRadius = 6
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.masksToBounds = true

        // remove any old shadow if you had one
        v.layer.shadowOpacity = 0
        v.layer.shadowRadius = 0
        v.layer.shadowOffset = .zero
        v.layer.shadowColor = nil
    }
}
