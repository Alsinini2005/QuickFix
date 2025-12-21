//
//  TechnicianTableViewCell.swift
//  QuickFix
//
//  Created by Zainab Aman on 20/12/2025.
//

import UIKit

struct Technician {
    var image : UIImage
    var userID : String
    var name : String
    var email : String
    var password : String
    var phoneNumber : Int
    
}

let arrTechnicians = [
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1001", name: "Mohammed Aman", email: "mohammed@gmail.com", password: "pass123", phoneNumber: 9876543210),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1002", name: "Ali Khan", email: "ali@gmail.com", password: "pass456", phoneNumber: 9876543211),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1003", name: "Sara Ahmed", email: "sara@gmail.com", password: "pass789", phoneNumber: 9876543212),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1004", name: "Hassan Raza", email: "hassan@gmail.com", password: "pass321", phoneNumber: 9876543213),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1005", name: "Ayesha Noor", email: "ayesha@gmail.com", password: "pass654", phoneNumber: 9876543214)
]

class Feature9_1 : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var TechnicianTableView : UITableView!
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TechnicianTableView.dataSource = self
        TechnicianTableView.delegate = self
        print("viewDidLoad called")
        
        
    }
 
    func  tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrTechnicians.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "technicianCell" ) as! TechnicianTableViewCell;
        let technicianData = arrTechnicians[indexPath.row]
        cell.imgProfilePhoto.image = technicianData.image
        cell.lblName.text = technicianData.name
        cell.lblEmail.text = technicianData.email
        
        print(technicianData.name)
        return cell
    }
    
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            print(arrTechnicians[indexPath.row])
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let vc = storyboard.instantiateViewController(withIdentifier: "Feature9_2") as! Feature9_2
            vc.technician = arrTechnicians[indexPath.row]
            self.navigationController?.pushViewController(vc, animated: true)
    
        }
    
    
}

class TechnicianTableViewCell: UITableViewCell {

    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
}




class Feature9_2 : UIViewController {

    @IBOutlet weak var imgTechnicianPhoto: UIImageView!
    @IBOutlet weak var lblUserID: UILabel!
    @IBOutlet weak var lblFullName: UILabel!
    @IBOutlet weak var lblEmailAddress: UILabel!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    
    var technician: Technician?

    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let tech = technician {
            imgTechnicianPhoto.image = tech.image
            lblUserID.text = tech.userID
            lblFullName.text = tech.name
            lblEmailAddress.text = tech.email
            lblPassword.text = tech.password
            lblPhoneNumber.text = "+973 \(tech.phoneNumber)"
        }
        
        
        print("Feature9_2")

    }
        
}

class Feature9_4 : UIViewController {
        
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("Feature9_4")

    }
        
}



