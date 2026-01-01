//
//  TechnicianTableViewCell.swift
//  QuickFix
//
//  Created by Mohd Aman on 20/12/2025.
//

import UIKit

struct Technician {
    var image : String
    var userID : String
    var name : String
    var email : String
    var password : String?
    var phoneNumber : String
    
}

var arrTechnicians = [
    Technician(image: "person.fill", userID: "5B084245", name: "Mohammed Aman", email: "mohammed@gmail.com", password: "pass123", phoneNumber: "13497852"),
    Technician(image: "imgProfilePhoto", userID: "5B085764", name: "Ali Khan", email: "ali@gmail.com", password: "pass456", phoneNumber: "9986243"),
    Technician(image: "imgProfilePhoto", userID: "5B031457", name: "Sara Ahmed", email: "sara@gmail.com", password: "pass789", phoneNumber: "36455198"),
    Technician(image: "imgProfilePhoto", userID: "5B054478", name: "Hassan Raza", email: "hassan@gmail.com", password: "pass321", phoneNumber: "66315874"),
    Technician(image: "imgProfilePhoto", userID: "5B084456", name: "Ayesha Noor", email: "ayesha@gmail.com", password: "pass654", phoneNumber: "31657848"),

]

// Helper to get Documents directory URL
func documentsDirectory() -> URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}

// Save UIImage to Documents and return filename
func saveImageToDocuments(_ image: UIImage, for userID: String) -> String {
    let filename = "custom_\(userID).png"
    let fileURL = documentsDirectory().appendingPathComponent(filename)
    
    if let data = image.pngData() {
        try? data.write(to: fileURL)
    }
    return filename
}

// Load image from either asset catalog or Documents
func loadImage(named imageName: String) -> UIImage? {
    // First try bundled assets
    if let assetImage = UIImage(named: imageName) {
        return assetImage
    }
    
    // Then try Documents directory
    let fileURL = documentsDirectory().appendingPathComponent(imageName)
    if let image = UIImage(contentsOfFile: fileURL.path) {
        return image
    }
    
    // Fallback
    return UIImage(systemName: "person.crop.circle.fill")
}

extension UITableView {

    func applySoftBorder(
        cornerRadius: CGFloat = 10,
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
        layer.cornerRadius = 10
        layer.borderWidth = 0
        layer.borderColor = UIColor.lightGray.withAlphaComponent(0.35).cgColor
        clipsToBounds = true
    }
}

extension UITextField {
    func applySoftBorder(){
        layer.cornerRadius = 10
        layer.borderWidth = 0
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
        
        txtSearch.applySoftBorder()

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
        cell.imgProfilePhoto.image = loadImage(named: technician.image)
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

        imgProfilePhoto.image = loadImage(named: tech.image)
        lblUserID.text = tech.userID
        lblFullName.text = tech.name
        lblEmailAddress.text = tech.email
        lblPassword.text = tech.password
        lblPhoneNumber.text = "+973 \(tech.phoneNumber)"
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2
        imgProfilePhoto.clipsToBounds = true
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
            imgProfilePhoto.image = loadImage(named: tech.image)
            txtUserID.text = tech.userID
            txtFullName.text = (tech.name)
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
            let userID = txtUserID.text?.trimmingCharacters(in: .whitespacesAndNewlines), !userID.isEmpty,
            let name = txtFullName.text?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty,
            let email = txtEmailAddress.text?.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty,
            let password = txtPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines), !password.isEmpty,
            let phone = txtPhoneNumber.text?.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty
        else {
            // Show alert if any field is empty
            let alert = UIAlertController(title: "Warning", message: "All fields are required.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        guard let index = technicianIndex else {
            let alert = UIAlertController(title: "Error", message: "Unable to save changes. Technician data is missing.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
            return
        }
        
        guard isValidBahrainPhone(phone) else {
               showAlert("Phone number must be 8 digits")
               return
           }
        
        // Handle image: if user picked a new one, save it
        var newImageName = arrTechnicians[index].image // keep old one by default
        
        if let currentImage = imgProfilePhoto.image,
           let originalTech = technician,
           currentImage.pngData() != loadImage(named: originalTech.image)?.pngData() { // Image changed
            
            newImageName = saveImageToDocuments(currentImage, for: userID)
        }
        
        arrTechnicians[index] = Technician(
            image: newImageName,
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
    
    func isValidBahrainPhone(_ phone: String) -> Bool {
        let regex = "^\\d{8}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }

    
    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Invalid Input",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
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
    
    var userID = String(UUID().uuidString.prefix(8))


    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserID.delegate = self
        txtFullName.delegate = self
        txtEmailAddress.delegate = self
        txtPhoneNumber.delegate = self
        
        txtUserID.text = userID
        
        txtPhoneNumber.keyboardType = .numberPad

        imgProfilePhoto.image = UIImage(systemName: "person.fill")!
        imgProfilePhoto.tintColor = UIColor(red: 40/255, green: 69/255, blue: 90/255, alpha: 1)
        
        
        btnAddTechnician.isHidden = true
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
    }
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
    
    @IBAction func btnAddTechnician(_ sender: Any) {
        guard let phone = txtPhoneNumber.text,
                 isValidBahrainPhone(phone) else {
               showAlert("Phone number must be 8 digits")
               return
           }

       arrTechnicians.append(
           Technician(
                image: "person.fill",
                userID: txtUserID.text!,
                name: txtFullName.text!,
                email: txtEmailAddress.text!,
                password: nil,
                phoneNumber: phone   // Stored as String
           )
       )

           navigationController?.popViewController(animated: true)

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
    
    func isValidBahrainPhone(_ phone: String) -> Bool {
        let regex = "^\\d{8}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }

    func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Invalid Input",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
