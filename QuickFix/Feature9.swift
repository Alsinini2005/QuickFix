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
    
    
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1001", name: "Mohammed Aman", email: "mohammed@gmail.com", password: "pass123", phoneNumber: "9876543210"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1002", name: "Ali Khan", email: "ali@gmail.com", password: "pass456", phoneNumber: "9876543211"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1003", name: "Sara Ahmed", email: "sara@gmail.com", password: "pass789", phoneNumber: "9876543212"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1004", name: "Hassan Raza", email: "hassan@gmail.com", password: "pass321", phoneNumber: "9876543213"),
    Technician(image: UIImage(named: "imgProfilePhoto")!, userID: "#1005", name: "Ayesha Noor", email: "ayesha@gmail.com", password: "pass654", phoneNumber: "9876543214")
]


extension UIImageView {
    func makeCircular() {
        layoutIfNeeded()
        layer.masksToBounds = true
        layer.cornerRadius = bounds.height / 2
        contentMode = .scaleAspectFill
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
}

class Feature9_1 : UIViewController,  UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var TechnicianTableView : UITableView!
    
    
    

 
    override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)

            TechnicianTableView.reloadData()
            print("Feature9_1 reloaded")
        }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        TechnicianTableView.delegate = self
        TechnicianTableView.dataSource = self
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
            vc.technicianIndex = indexPath.row
            self.navigationController?.pushViewController(vc, animated: true)
    
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
    }
    
    
    var technician: Technician?
    var technicianIndex : Int?
    
    override func viewWillAppear(_ animated: Bool) {
           super.viewWillAppear(animated)

           guard let index = technicianIndex else { return }

           technician = arrTechnicians[index]

           imgProfilePhoto.image = technician?.image
           lblUserID.text = (technician?.userID)
           lblFullName.text = technician?.name
           lblEmailAddress.text = technician?.email
           lblPassword.text = technician?.password
           lblPhoneNumber.text = "+973 \(technician?.phoneNumber ?? "")"
       }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        lblUserID.applySoftBorder()
        lblFullName.applySoftBorder()
        lblEmailAddress.applySoftBorder()
        lblPassword.applySoftBorder()
        lblPhoneNumber.applySoftBorder()
        
        print("Feature9_2")

    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imgProfilePhoto.makeCircular()
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
        if let tech = technician {
            imgProfilePhoto.image = tech.image
            txtUserID.text = tech.userID
            txtFullName.text = tech.name
            txtEmailAddress.text = tech.email
            txtPassword.text = tech.password
            txtPhoneNumber.text = (tech.phoneNumber)
        }
        
        
        txtUserID.applySoftBorder()
        txtFullName.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtPassword.applySoftBorder()
        txtPhoneNumber.applySoftBorder()
        
        print("Feature9_3")
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imgProfilePhoto.makeCircular()
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

        imgProfilePhoto.makeCircular()   // ⭐ CRITICAL
        picker.dismiss(animated: true)
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }

    
    @IBAction func btnAddPhoto(_ sender: Any) {
        let picker = UIImagePickerController()
            picker.delegate = self
            picker.sourceType = .photoLibrary
            picker.allowsEditing = true
            present(picker, animated: true, completion: nil)
    }
    
    @IBAction func btnSaveChanges(_ sender: Any) {
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
        
        if let index = technicianIndex {
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

        
    }
        
}

class Feature9_4 : UIViewController, UITextFieldDelegate {
        
    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var txtFullName: UITextField!
    @IBOutlet weak var txtEmailAddress: UITextField!
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
        imgProfilePhoto.makeCircular()
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



