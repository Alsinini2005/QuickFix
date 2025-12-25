//
//  TaskViewCell.swift
//  QuickFix
//
//  Created by BP-36-201-05 on 25/12/2025.
//

import UIKit

class TaskViewCell: UITableViewCell {

    @IBOutlet weak var ATImg: UIImageView!
    @IBOutlet weak var ATLbl1: UILabel!
    @IBOutlet weak var ATLbl2: UILabel!
    @IBOutlet weak var ATBtn: UIButton!
    @IBOutlet weak var PTImg: UIImageView!
    @IBOutlet weak var PTLbl1: UILabel!
    @IBOutlet weak var PTLbl2: UILabel!
    @IBOutlet weak var PTBtn: UIButton!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func setupCell(photo: UIImage, Task: String, TaskNo: Int){
        ATImg.image = photo
        ATLbl1.text = Task
        ATLbl2.text = "#\(TaskNo)"
        PTImg.image = photo
        PTLbl1.text = Task
        PTLbl2.text = "#\(TaskNo)"
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
//
