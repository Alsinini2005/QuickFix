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
        
        lblTicketID.text = "Ticket ID: \(ticket.ticketID)"
        lblName.text = "Ticket Name: \(ticket.name)"
        lblIssue.text = "Issue: \(ticket.issue)"
        lblLocation.text = "Location: \(ticket.location)"
        lblStatus.text = "Status: \(ticket.status)"
        lblUrgency.text = "Urgency: \(ticket.urgency)"
        lblCreatedAt.text = "Created: \(ticket.createdAt)"
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
