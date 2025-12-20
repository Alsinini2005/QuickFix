//
//  TechnicianTableViewCell.swift
//  QuickFix
//
//  Created by Zainab Aman on 20/12/2025.
//

import UIKit

struct Technician {
    var name : String
    var email : String
}


class Feature9_1 : UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var TechnicianTableView : UITableView!
    var arrTechnicians = [Technician]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TechnicianTableView.dataSource = self
        TechnicianTableView.delegate = self

        arrTechnicians.append(Technician.init(name: "Mohammed", email: "M@gmail.com"))
        arrTechnicians.append(Technician.init(name: "Ali", email: "A@gmail.com"))
        print("viewDidLoad called")

    }
    
    func  tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrTechnicians.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "technicianCell" ) as! TechnicianTableViewCell;
        let technicianData = arrTechnicians[indexPath.row]
        cell.lblName.text = technicianData.name
        cell.lblEmail.text = technicianData.email
        
        print(technicianData.name)
        return cell
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
