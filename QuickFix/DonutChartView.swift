//
//  DonutChartView.swift
//  QuickFix
//
//  Created by BP-36-212-09 on 29/12/2025.
//

import Foundation
import UIKit

final class DonutChartView: UIView {

    private let trackLayer = CAShapeLayer()
    private let pendingLayer = CAShapeLayer()
    private let inProgressLayer = CAShapeLayer()
    private let completedLayer = CAShapeLayer()

    private let centerLabel = UILabel()

    // Config
    var lineWidth: CGFloat = 18 { didSet { setNeedsLayout() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear

        // Track (gray circle behind)
        trackLayer.fillColor = UIColor.clear.cgColor
        trackLayer.strokeColor = UIColor.systemGray5.cgColor
        trackLayer.lineCap = .round
        layer.addSublayer(trackLayer)

        // Segments
        [pendingLayer, inProgressLayer, completedLayer].forEach {
            $0.fillColor = UIColor.clear.cgColor
            $0.lineCap = .round
            layer.addSublayer($0)
        }

        // Colors (change if you want)
        pendingLayer.strokeColor = UIColor.systemRed.cgColor
        inProgressLayer.strokeColor = UIColor.systemOrange.cgColor
        completedLayer.strokeColor = UIColor.systemGreen.cgColor

        // Center label
        centerLabel.textAlignment = .center
        centerLabel.numberOfLines = 2
        centerLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        centerLabel.textColor = .label
        addSubview(centerLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        let radius = min(bounds.width, bounds.height) / 2 - lineWidth/2
        let center = CGPoint(x: bounds.midX, y: bounds.midY)

        let startAngle = -CGFloat.pi / 2
        let endAngle = startAngle + 2 * CGFloat.pi

        let path = UIBezierPath(arcCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true).cgPath

        [trackLayer, pendingLayer, inProgressLayer, completedLayer].forEach {
            $0.path = path
            $0.lineWidth = lineWidth
        }

        centerLabel.frame = CGRect(x: 0, y: 0, width: bounds.width, height: bounds.height)
    }

    /// Update donut with counts
    func setData(pending: Int, inProgress: Int, completed: Int) {
        let total = max(1, pending + inProgress + completed)

        // fractions
        let p = CGFloat(pending) / CGFloat(total)
        let ip = CGFloat(inProgress) / CGFloat(total)
        let c = CGFloat(completed) / CGFloat(total)

        // stroke ranges (stacked)
        pendingLayer.strokeStart = 0
        pendingLayer.strokeEnd = p

        inProgressLayer.strokeStart = p
        inProgressLayer.strokeEnd = p + ip

        completedLayer.strokeStart = p + ip
        completedLayer.strokeEnd = p + ip + c

        centerLabel.text = "Total\n\(pending + inProgress + completed)"
    }
}
