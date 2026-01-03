
import UIKit

// MARK: - Models
struct TicketDetails {
    let ticketID: String
    let name: String
    let location: String
    let issue: String
    let status: String
    let urgency: String
    let createdAt: String
}

// MARK: - Sample Data
/// Temporary mock data (replace with API later)
var tickets: [TicketDetails] = [
    TicketDetails(
        ticketID: "#245",
        name: "Wi-Fi outage on 3rd floor Wi-Fi outage on 3rd floor",
        location: "Building A",
        issue: "Network Failure",
        status: "Assigned",
        urgency: "Low",
        createdAt: "25-5-2025"
    )
]

// MARK: - UILabel Extensions
extension UILabel {

    func setColoredText(
        fullText: String,
        prefix: String,
        prefixColor: UIColor,
        valueColor: UIColor
    ) {
        let attributed = NSMutableAttributedString(
            string: fullText,
            attributes: [.foregroundColor: valueColor]
        )

        if let range = fullText.range(of: prefix) {
            attributed.addAttribute(
                .foregroundColor,
                value: prefixColor,
                range: NSRange(range, in: fullText)
            )
        }

        attributedText = attributed
    }

    func applySoftBorder(corners: CACornerMask? = nil) {
        layer.cornerRadius = 6
        layer.borderWidth = 0
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
        if let corners = corners {
            layer.maskedCorners = corners
        }
        clipsToBounds = true
    }
}

class TopAlignedLabel: UILabel {

    override func textRect(
        forBounds bounds: CGRect,
        limitedToNumberOfLines numberOfLines: Int
    ) -> CGRect {
        let rect = super.textRect(
            forBounds: bounds,
            limitedToNumberOfLines: numberOfLines
        )
        return CGRect(
            x: rect.origin.x,
            y: bounds.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    override func drawText(in rect: CGRect) {
        let textRect = self.textRect(
            forBounds: rect,
            limitedToNumberOfLines: numberOfLines
        )
        super.drawText(in: textRect)
    }
}


// MARK: - View Controller
class Feature8: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var lblTicketID: TopAlignedLabel!
    @IBOutlet private weak var lblName: TopAlignedLabel!
    @IBOutlet private weak var lblIssue: TopAlignedLabel!
    @IBOutlet private weak var lblLocation: TopAlignedLabel!
    @IBOutlet private weak var lblStatus: TopAlignedLabel!
    @IBOutlet private weak var lblUrgency: TopAlignedLabel!
    @IBOutlet private weak var lblCreatedAt: TopAlignedLabel!
    @IBOutlet private weak var lblTechnician: TopAlignedLabel!
    @IBOutlet private weak var lblEscalationReason: TopAlignedLabel!

    // MARK: - Properties
    var ticket = tickets.first!

    private let prefixColor = UIColor(red: 40/255, green: 69/255, blue: 90/255, alpha: 1)
    private let valueColor = UIColor(red: 40/255, green: 69/255, blue: 90/255, alpha: 0.75)

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateTicketData()
        updateLabelHeight(for: lblName)
    }

    // MARK: - UI Setup
    private func setupUI() {
        lblTicketID.applySoftBorder(corners: [.layerMinXMinYCorner, .layerMaxXMinYCorner])
        lblCreatedAt.applySoftBorder(corners: [.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
        lblTechnician.applySoftBorder()
        lblEscalationReason.applySoftBorder()
    }

    // MARK: - Data Binding
    private func populateTicketData() {
        lblTicketID.setColoredText(
            fullText: "Ticket ID: \(ticket.ticketID)",
            prefix: "Ticket ID:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblName.setColoredText(
            fullText: "Ticket Name: \(ticket.name)",
            prefix: "Ticket Name:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblIssue.setColoredText(
            fullText: "Issue: \(ticket.issue)",
            prefix: "Issue:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblLocation.setColoredText(
            fullText: "Location: \(ticket.location)",
            prefix: "Location:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblStatus.setColoredText(
            fullText: "Status: \(ticket.status)",
            prefix: "Status:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblUrgency.setColoredText(
            fullText: "Urgency: \(ticket.urgency)",
            prefix: "Urgency:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblCreatedAt.setColoredText(
            fullText: "Created: \(ticket.createdAt)",
            prefix: "Created:",
            prefixColor: prefixColor,
            valueColor: valueColor
        )

        lblTechnician.text = "Jack"
        lblEscalationReason.text = "Fixing requires device formatting; all user data will be erased."
    }

    func updateLabelHeight(for label: UILabel) {
        label.sizeToFit()
        // If using a height constraint outlet (e.g., nameHeightConstraint):
        // nameHeightConstraint.constant = label.frame.height
    }
    // MARK: - Actions
    @IBAction func btnEscalate(_ sender: UIButton) { }
    @IBAction func btnReject(_ sender: UIButton) { }
}
