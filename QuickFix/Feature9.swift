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
    var password : String?
    var phoneNumber : String
    
}

var arrTechnicians = [
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1001", name: "Mohammed Aman", email: "mohammed@gmail.com", password: "pass123", phoneNumber: "9876543210"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1002", name: "Ali Khan", email: "ali@gmail.com", password: "pass456", phoneNumber: "9876543211"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1003", name: "Sara Ahmed", email: "sara@gmail.com", password: "pass789", phoneNumber: "9876543212"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1004", name: "Hassan Raza", email: "hassan@gmail.com", password: "pass321", phoneNumber: "9876543213"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1005", name: "Ayesha Noor", email: "ayesha@gmail.com", password: "pass654", phoneNumber: "9876543214"),

]
extension UITableView {

    func applySoftBorder(
        cornerRadius: CGFloat = 8,
        borderWidth: CGFloat = 1,
        borderColor: UIColor = UIColor.lightGray.withAlphaComponent(0.35)
    ) {
        layer.cornerRadius = cornerRadius
        layer.borderWidth = borderWidth
        layer.borderColor = borderColor.cgColor
        clipsToBounds = true
    }
    
    
}




extension UILabel {
    func applySoftBorder() {
        layer.cornerRadius = 5
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
        clipsToBounds = true
    }
}

extension UITextField {
    func applySoftBorder(){
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
        clipsToBounds = true    }
    func addLeftPadding(_ padding: CGFloat) {
            let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
            self.leftView = paddingView
            self.leftViewMode = .always
        }
}

class Feature9_1 : UIViewController,  UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var TechnicianTableView : UITableView!
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnAddTechnician: UIButton!
    private func updateTableHeight() {
        TechnicianTableView.layoutIfNeeded()
        tableHeightConstraint.constant = TechnicianTableView.contentSize.height
    }
    
    var filteredIndexes: [Int] = []
  
    var isSearching = false

 
    
   
    @objc func textDidChange(_ textField: UITextField) {
        btnSearch(textField)
    }

 
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

            if isSearching {
                let searchText = txtSearch.text?
                    .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                filteredIndexes = arrTechnicians.enumerated().compactMap { index, tech in
                    tech.name.lowercased().contains(searchText.lowercased()) ||
                    tech.email.lowercased().contains(searchText.lowercased()) ||
                    tech.userID.lowercased().contains(searchText.lowercased()) ||
                    tech.phoneNumber.contains(searchText)
                    ? index : nil
                }
            }

            TechnicianTableView.reloadData()
            updateTableHeight()
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        TechnicianTableView.reloadData()
        TechnicianTableView.applySoftBorder()
        TechnicianTableView.delegate = self
        TechnicianTableView.dataSource = self
        
        
        
        TechnicianTableView.backgroundColor = .clear
        TechnicianTableView.tableFooterView = UIView(frame: .zero)
        TechnicianTableView.alwaysBounceVertical = false
        TechnicianTableView.applySoftBorder(cornerRadius: 10)
        
        
        
        
        txtSearch.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

    }

    
    func  tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredIndexes.count : arrTechnicians.count
    }
    
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "technicianCell",
            for: indexPath
        ) as? TechnicianTableViewCell else {
            return UITableViewCell()
        }

        // Resolve the REAL index
        let technicianIndex: Int
        if isSearching {
            technicianIndex = filteredIndexes[indexPath.row]
        } else {
            technicianIndex = indexPath.row
        }

        let technician = arrTechnicians[technicianIndex]

        // Configure cell
        cell.imgProfilePhoto.image = technician.image
        cell.lblName.text = technician.name
        cell.lblEmail.text = technician.email

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "showTechnicianDetailsSegue", sender: indexPath)
    }


    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTechnicianDetailsSegue",
           let vc = segue.destination as? Feature9_2,
           let indexPath = sender as? IndexPath {

            // Resolve the REAL index in arrTechnicians
            let technicianIndex: Int
            if isSearching {
                technicianIndex = filteredIndexes[indexPath.row]
            } else {
                technicianIndex = indexPath.row
            }

            // Pass correct data
            vc.technicianIndex = technicianIndex
            vc.technician = arrTechnicians[technicianIndex]
        }
    }

    
    @IBAction func btnSearch(_ sender: Any) {
        let searchText = txtSearch.text?
               .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

           if searchText.isEmpty {
               isSearching = false
               filteredIndexes.removeAll()
           } else {
               isSearching = true
               filteredIndexes = arrTechnicians.enumerated().compactMap { index, tech in
                   tech.name.lowercased().contains(searchText.lowercased()) ||
                   tech.email.lowercased().contains(searchText.lowercased()) ||
                   tech.userID.lowercased().contains(searchText.lowercased()) ||
                   tech.phoneNumber.contains(searchText)
                   ? index : nil
               }
           }

           TechnicianTableView.reloadData()
           updateTableHeight()
     }
 
    
    
}

class TechnicianTableViewCell: UITableViewCell {
    
    @IBOutlet weak var imgProfilePhoto : UIImageView!
    @IBOutlet weak var lblName: UILabel!
    @IBOutlet weak var lblEmail: UILabel!
    
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.clipsToBounds = true
    }


    override func layoutSubviews() {
        super.layoutSubviews()
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.height / 2
    }
    
}




class Feature9_2 : UIViewController {

    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var lblUserID: UILabel!
    @IBOutlet weak var lblFullName: UILabel!
    @IBOutlet weak var lblEmailAddress: UILabel!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    @IBAction func btnEdit(_ sender: Any) {
        print("Using Edit button...")
//            let storyboard = UIStoryboard(name: "Main", bundle: nil)
//            let vc = storyboard.instantiateViewController(withIdentifier: "Feature9_3") as! Feature9_3
//            vc.technician = technician
//            vc.technicianIndex = technicianIndex  // ← You might have forgotten this line!
//            self.navigationController?.pushViewController(vc, animated: true)
    }
    
    
    var technician: Technician?
    var technicianIndex : Int?
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)

           guard let index = technicianIndex else { return }
            technician = arrTechnicians[index]
            updateUI()

       }

    func updateUI() {
        guard let tech = technician else { return }

        imgProfilePhoto.image = tech.image
        lblUserID.text = tech.userID
        lblFullName.text = tech.name
        lblEmailAddress.text = tech.email
        lblPassword.text = tech.password
        lblPhoneNumber.text = tech.password
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2
        imgProfilePhoto.clipsToBounds = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
         imgProfilePhoto.image = technician?.image
         lblUserID.text = technician?.userID
         lblFullName.text = technician?.name
         lblEmailAddress.text = technician?.email
         lblPassword.text = technician?.password
         lblPhoneNumber.text = "+973 \(technician?.phoneNumber ?? "")"
        print("F2\nIs? \(technicianIndex)\nNot? \(technician)")

        lblUserID.applySoftBorder()
        lblFullName.applySoftBorder()
        lblEmailAddress.applySoftBorder()
        lblPassword.applySoftBorder()
        lblPhoneNumber.applySoftBorder()
        
        print("Feature9_2")

    }

    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editTechnicianSegue" {
            let vc = segue.destination as! Feature9_3
            vc.technician = technician
            vc.technicianIndex = technicianIndex
        }
    }

    
        
}



class Feature9_3: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var txtFullName: UITextField!
    @IBOutlet weak var txtEmailAddress: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    
    var technician: Technician?
    var technicianIndex: Int?
    
    	    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserID.addLeftPadding(5)
        txtFullName.addLeftPadding(5)
        txtEmailAddress.addLeftPadding(5)
        txtPassword.addLeftPadding(5)
        txtPhoneNumber.addLeftPadding(5)

        if let tech = technician {
            imgProfilePhoto.image = tech.image
            txtUserID.text = tech.userID
            txtFullName.text = (tech.name)
            txtEmailAddress.text = tech.email
            txtPassword.text = tech.password
            txtPhoneNumber.text = (tech.phoneNumber)
        }
        
        
                print("F3\nIs? \(technicianIndex)\nNot? \(technician)")
        txtUserID.applySoftBorder()
        txtFullName.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtPassword.applySoftBorder()
        txtPhoneNumber.applySoftBorder()
        
        print("Feature9_3")
    }
    
    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        if let editedImage = info[.editedImage] as? UIImage {
            imgProfilePhoto.image = editedImage
        } else if let originalImage = info[.originalImage] as? UIImage {
            imgProfilePhoto.image = originalImage
        }
        
        picker.dismiss(animated: true)
    }
    
    
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func btnEditPhoto(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true, completion: nil)
    }
    
    
    @IBAction func btnSaveChanges(_ sender: Any) {
        print("checking...")
        guard
            let userID = txtUserID.text, !userID.isEmpty,
            let name = txtFullName.text, !name.isEmpty,
            let email = txtEmailAddress.text, !email.isEmpty,
            let password = txtPassword.text, !password.isEmpty,
            let phone = txtPhoneNumber.text, !phone.isEmpty
        else {
            // Show alert if any field is empty
            let alert = UIAlertController(title: "Warning", message: "All fields are required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        print("technicianIndex=\(technicianIndex)")
        
        guard let index = technicianIndex else {  let alert = UIAlertController(title: "Error", message: "Unable to save changes. Technician data is missing.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return }
         arrTechnicians[index] = Technician(
                        image: imgProfilePhoto.image ?? UIImage(),
                        userID: userID,
                        name: name,
                        email: email,
                        password: password,
                        phoneNumber: phone
                    )
                    print("Editing \(arrTechnicians[index])")
                    navigationController?.popViewController(animated: true)
                
        
    }
        
        
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2
        imgProfilePhoto.clipsToBounds = true
    }
    
    
}





@IBDesignable
class CircularImageView: UIImageView {
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = frame.width / 2
        clipsToBounds = true
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        didSet {
            layer.borderWidth = borderWidth
        }
    }
    
    @IBInspectable var borderColor: UIColor = .clear {
        didSet {
            layer.borderColor = borderColor.cgColor
        }
    }
    
}



class Feature9_4 : UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var txtFullName: UITextField!
    @IBOutlet weak var txtEmailAddress: UITextField!
    @IBOutlet weak var txtPassword : UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    
    @IBOutlet weak var btnAddTechnician: UIButton!
    
   

    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserID.delegate = self
        txtFullName.delegate = self
        txtEmailAddress.delegate = self
        txtPhoneNumber.delegate = self
        
        imgProfilePhoto.image = UIImage(named: "imgProfilePhoto")!
         
        
        
        
        btnAddTechnician.isHidden = true   // or isEnabled = false
        imgProfilePhoto.alpha.round()
            // Listen for text changes
        txtUserID.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        txtFullName.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        txtEmailAddress.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        txtPhoneNumber.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        
        txtUserID.applySoftBorder()
        txtFullName.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtPhoneNumber.applySoftBorder()
        
        print("Feature9_4")

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2
        imgProfilePhoto.clipsToBounds = true
    }
    
    @objc func textDidChange() {
        let allFilled =
            !(txtUserID.text?.isEmpty ?? true) &&
            !(txtFullName.text?.isEmpty ?? true) &&
            !(txtEmailAddress.text?.isEmpty ?? true) &&
            !(txtPhoneNumber.text?.isEmpty ?? true)

        btnAddTechnician.isHidden = !allFilled
        // OR:
        // btnAddTechnician.isEnabled = allFilled
    }
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtUserID {
            txtFullName.becomeFirstResponder()
        }else if textField == txtFullName {
            txtEmailAddress.becomeFirstResponder()
        }else if textField == txtEmailAddress {
            txtPhoneNumber.becomeFirstResponder()
        }
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func btnAddTechnician(_ sender: Any) {
        arrTechnicians.append(Technician.init(image: UIImage(named: "imgProfilePhoto")!, userID: txtUserID.text! , name: txtFullName.text!, email: txtEmailAddress.text!, password: nil, phoneNumber: txtPhoneNumber.text!))
            navigationController?.popViewController(animated: true)

    }
    
        
}



