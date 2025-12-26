//
//import UIKit
//
//
//struct TicketDetails {
//    var ticketID : String
//    var name : String
//    var location : String
//    var issue : String
//    var status : String
//    var urgency : String
//    var createdAt : String
//    
//}
//
//
//extension UILabel {
//    
//    
//    func setColoredText(
//            fullText: String,
//            prefix: String,
//            prefixColor: UIColor,
//            valueColor: UIColor
//        ) {
//            let attributedText = NSMutableAttributedString(
//                string: fullText,
//                attributes: [.foregroundColor: valueColor]
//            )
//
//            if let range = fullText.range(of: prefix) {
//                let nsRange = NSRange(range, in: fullText)
//                attributedText.addAttribute(
//                    .foregroundColor,
//                    value: prefixColor,
//                    range: nsRange
//                )
//            }
//
//            self.attributedText = attributedText
//        }
//    
//    func applyAboveSoftBorder() {
//        layer.cornerRadius = 5
//        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
//
//        layer.maskedCorners = [
//            .layerMinXMinYCorner, // top-left
//            .layerMaxXMinYCorner  // top-right
//        ]
//
//        clipsToBounds = true
//    }
//    
//    func applyUnderSoftBorder() {
//        layer.cornerRadius = 5
//        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
//
//        layer.maskedCorners = [
//            .layerMinXMaxYCorner,
//            .layerMaxXMaxYCorner
//        ]
//
//        clipsToBounds = true
//    }
//}
//
//var arrTickets = [
//    TicketDetails(ticketID: "#245", name: "Wi‑Fi outage on 3rd floor", location: "Building A", issue: "Network Failure", status: "Assigned",  urgency: "Low", createdAt: "25-5-2025" )
//]
//
//class Feature8: UIViewController {
//
//    
//    
//    @IBOutlet weak var lblTicketID: UILabel!
//    @IBOutlet weak var lblName: UILabel!
//    @IBOutlet weak var lblIssue: UILabel!
//    @IBOutlet weak var lblLocation: UILabel!
//    @IBOutlet weak var lblStatus: UILabel!
//    @IBOutlet weak var lblUrgency: UILabel!
//    @IBOutlet weak var lblCreatedAt: UILabel!
//    
//    
//    @IBOutlet weak var lblTechnician: UILabel!
//    @IBOutlet weak var lblEscalationReason: UILabel!
//    
//    var ticket = TicketDetails(ticketID: "#245", name: "Wi‑Fi outage on 3rd floor", location: "Building A", issue: "Network Failure", status: "Assigned",  urgency: "Low", createdAt: "25-5-2025" )
//    
//    let prefixColor = UIColor(
//        red: 40/255,
//        green: 69/255,
//        blue: 90/255,
//        alpha: 1
//    )
//    let valueColor = UIColor.darkGray
//
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        //        guard let ticket = ticket else {
//        //            navigationController?.popViewController(animated: true)
//        //            return
//        //        }
//        
//        
//        lblTicketID.applyAboveSoftBorder()
//        lblCreatedAt.applyUnderSoftBorder()
//        lblTechnician.applySoftBorder()
//        lblEscalationReason.applySoftBorder()
//        
//
//        lblTicketID.setColoredText(
//            fullText: "Ticket ID: \(ticket.ticketID)",
//            prefix: "Ticket ID:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblName.setColoredText(
//            fullText: "Ticket Name: \(ticket.name)",
//            prefix: "Ticket Name:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblIssue.setColoredText(
//            fullText: "Issue: \(ticket.issue)",
//            prefix: "Issue:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblLocation.setColoredText(
//            fullText: "Location: \(ticket.location)",
//            prefix: "Location:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblStatus.setColoredText(
//            fullText: "Status: \(ticket.status)",
//            prefix: "Status:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblUrgency.setColoredText(
//            fullText: "Urgency: \(ticket.urgency)",
//            prefix: "Urgency:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        lblCreatedAt.setColoredText(
//            fullText: "Created: \(ticket.createdAt)",
//            prefix: "Created:",
//            prefixColor: prefixColor,
//            valueColor: valueColor
//        )
//
//        
//        lblTechnician.text = "Jack"
//        lblEscalationReason.text = "Fixing the need to format the device so all users information will be removed "
//        
//    }
//    
//    @IBAction func btnEscalate(_ sender: Any) {
//    }
//    
//    @IBAction func btnReject(_ sender: Any) {
//    }
//    
//    
//    
//    
//    
//    
//    
//    
//    
////    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
////        if segue.identifier == "showTicketDetails" {  // غيّر الاسم حسب الـ segue في Storyboard
////            guard let destinationVC = segue.destination as? Feature8,
////                  let selectedIndexPath = tableView.indexPathForSelectedRow else {
////                return
////            }
////            
////            destinationVC.ticket = arrTickets[selectedIndexPath.row]
////        }
////    }
//    
//    
//    
//}


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
        name: "Wi-Fi outage on 3rd floor",
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

// MARK: - View Controller
class Feature8: UIViewController {

    // MARK: - Outlets
    @IBOutlet private weak var lblTicketID: UILabel!
    @IBOutlet private weak var lblName: UILabel!
    @IBOutlet private weak var lblIssue: UILabel!
    @IBOutlet private weak var lblLocation: UILabel!
    @IBOutlet private weak var lblStatus: UILabel!
    @IBOutlet private weak var lblUrgency: UILabel!
    @IBOutlet private weak var lblCreatedAt: UILabel!
    @IBOutlet private weak var lblTechnician: UILabel!
    @IBOutlet private weak var lblEscalationReason: UILabel!

    // MARK: - Properties
    var ticket = tickets.first!

    private let prefixColor = UIColor(red: 40/255, green: 69/255, blue: 90/255, alpha: 1)
    private let valueColor = UIColor.darkGray

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        populateTicketData()
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

    // MARK: - Actions
    @IBAction func btnEscalate(_ sender: UIButton) { }
    @IBAction func btnReject(_ sender: UIButton) { }
}
