//
//  Feature8.swift
//  QuickFix
//
//  Created by Zainab Aman on 23/12/2025.
//

import UIKit


struct TicketDetails {
    var ticketID : String
    var name : String
    var location : String
    var issue : String
    var status : String
    var urgency : String
    var createdAt : String
    
}


extension UILabel {
    
    
    func setColoredText(
            fullText: String,
            prefix: String,
            prefixColor: UIColor,
            valueColor: UIColor
        ) {
            let attributedText = NSMutableAttributedString(
                string: fullText,
                attributes: [.foregroundColor: valueColor]
            )

            if let range = fullText.range(of: prefix) {
                let nsRange = NSRange(range, in: fullText)
                attributedText.addAttribute(
                    .foregroundColor,
                    value: prefixColor,
                    range: nsRange
                )
            }

            self.attributedText = attributedText
        }
    
    func applyAboveSoftBorder() {
        layer.cornerRadius = 5
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor

        layer.maskedCorners = [
            .layerMinXMinYCorner, // top-left
            .layerMaxXMinYCorner  // top-right
        ]

        clipsToBounds = true
    }
    
    func applyUnderSoftBorder() {
        layer.cornerRadius = 5
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor

        layer.maskedCorners = [
            .layerMinXMaxYCorner,
            .layerMaxXMaxYCorner
        ]

        clipsToBounds = true
    }
}

var arrTickets = [
    TicketDetails(ticketID: "#245", name: "Wi‑Fi outage on 3rd floor", location: "Building A", issue: "Network Failure", status: "Assigned",  urgency: "Low", createdAt: "25-5-2025" )
]

class Feature8: UIViewController {

    
    
    @IBOutlet weak var lblTicketID: UILabel!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblIssue: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblUrgency: UILabel!
    @IBOutlet weak var lblCreatedAt: UILabel!
    
    
    @IBOutlet weak var lblTechnician: UILabel!
    @IBOutlet weak var lblEscalationReason: UILabel!
    
    var ticket = TicketDetails(ticketID: "#245", name: "Wi‑Fi outage on 3rd floor", location: "Building A", issue: "Network Failure", status: "Assigned",  urgency: "Low", createdAt: "25-5-2025" )
    
    let prefixColor = UIColor(
        red: 40/255,
        green: 69/255,
        blue: 90/255,
        alpha: 1
    )
    let valueColor = UIColor.darkGray

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        guard let ticket = ticket else {
        //            navigationController?.popViewController(animated: true)
        //            return
        //        }
        
        
        lblTicketID.applyAboveSoftBorder()
        lblCreatedAt.applyUnderSoftBorder()
        lblTechnician.applySoftBorder()
        lblEscalationReason.applySoftBorder()
        

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
        lblEscalationReason.text = "Fixing the need to format the device so all users information will be removed "
        
    }
    
    @IBAction func btnEscalate(_ sender: Any) {
    }
    
    @IBAction func btnReject(_ sender: Any) {
    }
    
    
    
    
    
    
    
    
    
//    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//        if segue.identifier == "showTicketDetails" {  // غيّر الاسم حسب الـ segue في Storyboard
//            guard let destinationVC = segue.destination as? Feature8,
//                  let selectedIndexPath = tableView.indexPathForSelectedRow else {
//                return
//            }
//            
//            destinationVC.ticket = arrTickets[selectedIndexPath.row]
//        }
//    }
    
    
    
}
