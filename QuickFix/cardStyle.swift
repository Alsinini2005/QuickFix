import Foundation
import UIKit

extension UIView {
    func applyCardStyle(
        cornerRadius: CGFloat = 12,
        shadowColor: UIColor = .black,
        shadowOpacity: Float = 0.08,
        shadowOffset: CGSize = CGSize(width: 0, height: 6),
        shadowRadius: CGFloat = 12
    ) {
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = false

        layer.shadowColor = shadowColor.cgColor
        layer.shadowOpacity = shadowOpacity
        layer.shadowOffset = shadowOffset
        layer.shadowRadius = shadowRadius

        backgroundColor = .systemBackground
    }
}
