//
//  TaskViewController.swift
//  QuickFix
//
//  Created by BP-36-201-05 on 25/12/2025.
//

import UIKit

class TaskViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var TableViewA: UITableView!
    @IBOutlet weak var TableViewP: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        TableViewA.delegate = self
        TableViewA.dataSource = self
        TableViewP.delegate = self
        TableViewP.dataSource = self
       
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 0
    }
   
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TaskCellA") as! TaskViewCell
        
        return cell
    }

}
