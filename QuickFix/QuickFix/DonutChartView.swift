import UIKit

final class DonutChartView: UIView {

    struct Segment {
        let value: CGFloat
        let color: UIColor
    }

    var segments: [Segment] = [] {
        didSet { setNeedsLayout() }
    }

    private let holeLayer = CAShapeLayer()
    private var segmentLayers: [CAShapeLayer] = []

    private var lastBounds: CGRect = .zero
    private var lastSignature: String = ""

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
        layer.addSublayer(holeLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        drawChartIfNeeded()
    }
    // Put this inside DonutChartView (below commonInit for example)
    func setData(pending: Int, inProgress: Int, completed: Int) {
        segments = [
            Segment(value: CGFloat(pending),    color: .systemOrange),
            Segment(value: CGFloat(inProgress), color: .systemBlue),
            Segment(value: CGFloat(completed),  color: .systemGreen)
        ]

        // Force redraw even if bounds didn't change (optional but helpful)
        lastSignature = ""
        setNeedsLayout()
    }


    private func drawChartIfNeeded() {
        // Prevent heavy redraw loops
        let signature = segments.map { "\($0.value)" }.joined(separator: "|")
        guard bounds != .zero else { return }
        guard bounds != lastBounds || signature != lastSignature else { return }

        lastBounds = bounds
        lastSignature = signature
        drawChart()
    }

    private func drawChart() {
        // Remove old layers
        segmentLayers.forEach { $0.removeFromSuperlayer() }
        segmentLayers.removeAll()

        let total = segments.reduce(CGFloat(0)) { $0 + $1.value }
        guard total > 0 else {
            holeLayer.path = nil
            return
        }

        let lineWidth: CGFloat = max(10, min(bounds.width, bounds.height) * 0.18)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - lineWidth / 2

        var startAngle: CGFloat = -.pi / 2

        for seg in segments where seg.value > 0 {
            let endAngle = startAngle + (2 * .pi) * (seg.value / total)

            let path = UIBezierPath(
                arcCenter: center,
                radius: radius,
                startAngle: startAngle,
                endAngle: endAngle,
                clockwise: true
            )

            let segLayer = CAShapeLayer()
            segLayer.path = path.cgPath
            segLayer.fillColor = UIColor.clear.cgColor
            segLayer.strokeColor = seg.color.cgColor
            segLayer.lineWidth = lineWidth
            segLayer.lineCap = .butt

            layer.addSublayer(segLayer)
            segmentLayers.append(segLayer)

            startAngle = endAngle
        }

        // Draw the hole in the center
        let holePath = UIBezierPath(
            arcCenter: center,
            radius: max(0, radius - lineWidth / 2),
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )

        holeLayer.path = holePath.cgPath
        holeLayer.fillColor = UIColor.systemBackground.cgColor
        holeLayer.strokeColor = UIColor.clear.cgColor
        holeLayer.zPosition = 999 // ensure on top
    }
}
