//
//  TechnicianTableViewCell.swift
//  QuickFix
//
//  Created by Mohd Aman on 20/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Cloudinary

struct Technician {
    var profileImageURL: String?
    var userID: String
    var name: String
    var email: String
    var phoneNumber: String
    var password: String?
    var uid: String?  // Make uid optional
}

var arrTechnicians: [Technician] = []

// Load image from URL or fallback
func loadImage(from urlString: String?, completion: @escaping (UIImage?) -> Void) {
    guard let urlString = urlString, let url = URL(string: urlString) else {
        completion(UIImage(systemName: "person.crop.circle.fill"))
        return
    }
    URLSession.shared.dataTask(with: url) { data, _, _ in
        guard let data = data, let image = UIImage(data: data) else {
            completion(UIImage(systemName: "person.crop.circle.fill"))
            return
        }
        DispatchQueue.main.async {
            completion(image)
        }
    }.resume()
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
        clipsToBounds = true
    }
    func addLeftPadding(_ padding: CGFloat) {
        let paddingView = UIView(frame: CGRect(x: 0, y: 0, width: padding, height: self.frame.height))
        self.leftView = paddingView
        self.leftViewMode = .always
    }
}

class TechnicianList: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var TechnicianTableView: UITableView!
    @IBOutlet weak var txtSearch: UITextField!
    @IBOutlet weak var tableHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var btnAddTechnician: UIButton!
    
    private let db = Firestore.firestore()
    
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
        fetchTechniciansFromFirestore()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTableHeight()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
    
    private func fetchTechniciansFromFirestore() {
        db.collection("Technicians_Mohammed").getDocuments { [weak self] snapshot, error in
            guard let self = self else { return }
           
            if let error = error {
                print("Error fetching technicians: \(error)")
                return
            }
           
            guard let documents = snapshot?.documents else {
                return
            }
           
            // Clear old data (important to avoid duplicates)
            arrTechnicians.removeAll()
           
            for document in documents {
                let data = document.data()
                
                let technician = Technician(
                    profileImageURL: data["image"] as? String,
                    userID: data["userID"] as? String ?? document.documentID,
                    name: data["name"] as? String ?? "",
                    email: data["email"] as? String ?? "",
                    phoneNumber: data["phoneNumber"] as? String ?? "",
                    password: data["password"] as? String,
                    uid: document.documentID // Firebase document ID is the UID
                )
               
                arrTechnicians.append(technician)
            }
           
            print("Technicians count:", arrTechnicians.count)
            
            if self.isSearching {
                let searchText = self.txtSearch.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self.filteredIndexes = arrTechnicians.enumerated().compactMap { index, tech in
                    tech.name.lowercased().contains(searchText.lowercased()) ||
                    tech.email.lowercased().contains(searchText.lowercased()) ||
                    tech.userID.lowercased().contains(searchText.lowercased()) ||
                    tech.phoneNumber.contains(searchText)
                    ? index : nil
                }
            }
            
            DispatchQueue.main.async {
                self.TechnicianTableView.reloadData()
                self.updateTableHeight()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isSearching ? filteredIndexes.count : arrTechnicians.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "technicianCell", for: indexPath) as? TechnicianTableViewCell else {
            return UITableViewCell()
        }
        
        let technicianIndex = isSearching ? filteredIndexes[indexPath.row] : indexPath.row
        let technician = arrTechnicians[technicianIndex]
        
        cell.lblName.text = technician.name
        cell.lblEmail.text = technician.email
        
        loadImage(from: technician.profileImageURL) { image in
            DispatchQueue.main.async {
                cell.imgProfilePhoto.image = image
            }
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let technicianIndex = isSearching ? filteredIndexes[indexPath.row] : indexPath.row
        let technician = arrTechnicians[technicianIndex]
        
        if let uid = technician.uid {
            performSegue(withIdentifier: "showTechnicianDetailsSegue", sender: uid)
        } else {
            showAlert("Error", "Cannot view technician details: UID not found")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showTechnicianDetailsSegue",
           let vc = segue.destination as? ShowTechnicianDetails,
           let uid = sender as? String {
            vc.technicianUID = uid
        }
    }
    
    @IBAction func btnSearch(_ sender: Any) {
        let searchText = txtSearch.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        
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
    
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

class TechnicianTableViewCell: UITableViewCell {
    @IBOutlet weak var imgProfilePhoto: UIImageView!
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

class ShowTechnicianDetails: UIViewController {
    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var lblUserID: UILabel!
    @IBOutlet weak var lblFullName: UILabel!
    @IBOutlet weak var lblEmailAddress: UILabel!
    @IBOutlet weak var lblPassword: UILabel!
    @IBOutlet weak var lblPhoneNumber: UILabel!
    
    var technicianUID: String?
    private let db = Firestore.firestore()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let uid = technicianUID {
            fetchTechnicianFromFirestore(uid: uid)
        }
    }
    
    private func fetchTechnicianFromFirestore(uid: String) {
        db.collection("Technicians_Mohammed")
          .document(uid)
          .getDocument(source: .server) { [weak self] snapshot, error in

            guard let self = self else { return }

            if let error = error {
                print("❌ Error fetching technician:", error.localizedDescription)
                self.showAlert("Error", "Failed to load technician")
                return
            }

            guard let snapshot = snapshot, snapshot.exists,
                  let data = snapshot.data() else {
                self.showAlert("Error", "Technician not found")
                return
            }

            // ✅ This is a SINGLE document (dictionary), not an array
            DispatchQueue.main.async {
                self.updateUI(with: data, uid: uid)
            }
        }
    }

    
    private func updateUI(with data: [String: Any], uid: String) {
        lblUserID.text = data["userID"] as? String ?? uid
        lblFullName.text = data["name"] as? String ?? ""
        lblEmailAddress.text = data["email"] as? String ?? ""
        
        if let phone = data["phoneNumber"] as? String, !phone.isEmpty {
            lblPhoneNumber.text = "+973 \(phone)"
        } else {
            lblPhoneNumber.text = "N/A"
        }
        
        loadImage(from: data["image"] as? String) { image in
            DispatchQueue.main.async {
                self.imgProfilePhoto.image = image
            }
        }
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
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editTechnicianSegue",
           let vc = segue.destination as? EditTechnicianDetails,
           let uid = technicianUID {
            vc.technicianUID = uid
        }
    }
    
    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    @IBAction func btnEdit(_ sender: Any) {
        
    }
    
}

class EditTechnicianDetails: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    @IBOutlet weak var imgProfilePhoto: UIImageView!
    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var txtFullName: UITextField!
    @IBOutlet weak var txtEmailAddress: UITextField!
    
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    
    var technicianUID: String?
    var selectedProfileImage: UIImage?
    
    private let db = Firestore.firestore()
    private let cloudName = "dzthj3w6v"
    private let unsignedUploadPreset = "profile"
    
    private lazy var cloudinary: CLDCloudinary = {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        return CLDCloudinary(configuration: config)
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let uid = technicianUID {
            fetchTechnicianFromFirestore(uid: uid)
        }
    }
    
    private func fetchTechnicianFromFirestore(uid: String) {
        db.collection("Technicians_Mohammed").document(uid).getDocument { [weak self] snapshot, error in
            guard let self = self else { return }
            if let error = error {
                print("Error fetching technician: \(error)")
                return
            }
            
            guard let data = snapshot?.data() else {
                self.showAlert("Error", "Technician not found")
                return
            }
            
            DispatchQueue.main.async {
                self.updateUI(with: data)
            }
        }
    }
    
    private func updateUI(with data: [String: Any]) {
        txtUserID.text = data["userID"] as? String
        txtFullName.text = data["name"] as? String
        txtEmailAddress.text = data["email"] as? String
        txtPassword.text = data["password"] as? String
        txtPhoneNumber.text = data["phoneNumber"] as? String
        
        loadImage(from: data["image"] as? String) { image in
            DispatchQueue.main.async {
                self.imgProfilePhoto.image = image
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtUserID.addLeftPadding(5)
        txtFullName.addLeftPadding(5)
        txtEmailAddress.addLeftPadding(5)
        txtPassword.addLeftPadding(5)
        txtPhoneNumber.addLeftPadding(5)
        
//        txtUserID.isEnabled = false // UID not editable
//        txtEmailAddress.isEnabled = false // Email not editable in this view
        
        txtUserID.applySoftBorder()
        txtFullName.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtPassword.applySoftBorder()
        txtPhoneNumber.applySoftBorder()
        
        setupProfileImageTap()
    }
    
    private func setupProfileImageTap() {
        imgProfilePhoto.isUserInteractionEnabled = true
        imgProfilePhoto.clipsToBounds = true
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        imgProfilePhoto.addGestureRecognizer(tap)
    }
    
    @objc private func profileImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        let pickedImage = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        
        guard let image = pickedImage else {
            picker.dismiss(animated: true)
            return
        }
        
        imgProfilePhoto.image = image
        selectedProfileImage = image
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        imgProfilePhoto.contentMode = .scaleAspectFill
        imgProfilePhoto.layer.cornerRadius = imgProfilePhoto.frame.width / 2
        imgProfilePhoto.clipsToBounds = true
    }
    
    @IBAction func btnSaveChanges(_ sender: Any) {

        guard let uid = technicianUID else { return }

        let userID = txtUserID.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = txtFullName.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = txtEmailAddress.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = txtPassword.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = txtPhoneNumber.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if userID.isEmpty || name.isEmpty || email.isEmpty || password.isEmpty || phone.isEmpty {
            showAlert("Warning", "All fields are required.")
            return
        }

        guard isValidBahrainPhone(phone) else {
            showAlert("Invalid Input", "Phone number must be 8 digits")
            return
        }

        if let newImage = selectedProfileImage {
            uploadProfileImageToCloudinary(newImage) { [weak self] url in
                self?.updateFirestore(
                    uid: uid,
                    userID: userID,
                    name: name,
                    email: email,
                    password: password,
                    phone: phone,
                    profileImageURL: url
                )
            }
        } else {
            updateFirestore(
                uid: uid,
                userID: userID,
                name: name,
                email: email,
                password: password,
                phone: phone,
                profileImageURL: nil
            )
        }
    }
    
    private func updateFirestore(
        uid: String,
        userID: String,
        name: String,
        email: String,
        password: String,
        phone: String,
        profileImageURL: String?
    ) {

        var updates: [String: Any] = [
            "userID": userID,
            "name": name,
            "email": email,
            "password": password,
            "phoneNumber": phone
        ]

        if let url = profileImageURL {
            updates["image"] = url
        }

        db.collection("Technicians_Mohammed")
            .document(uid)
            .updateData(updates) { [weak self] error in

                if let error = error {
                    self?.showAlert("Error", error.localizedDescription)
                } else {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
    }

    
    private func uploadProfileImageToCloudinary(_ image: UIImage, completion: @escaping (String) -> Void) {
        guard let data = image.jpegData(compressionQuality: 0.75) else { return }
        
        let params = CLDUploadRequestParams()
        params.setResourceType("image")
        params.setFolder("profile_images")
        
        cloudinary.createUploader().upload(
            data: data,
            uploadPreset: unsignedUploadPreset,
            params: params,
            progress: nil
        ) { result, error in
            if let error = error {
                self.showAlert("Upload Error", error.localizedDescription)
                return
            }
            
            guard let secureUrl = result?.secureUrl else {
                self.showAlert("Upload Error", "No URL returned.")
                return
            }
            
            completion(secureUrl)
        }
    }
    
    @IBAction func btnEditPhoto(_ sender: Any) {
           let picker = UIImagePickerController()
           picker.delegate = self
           picker.sourceType = .photoLibrary
           picker.allowsEditing = true
           present(picker, animated: true, completion: nil)
       }
    
    func isValidBahrainPhone(_ phone: String) -> Bool {
        let regex = "^\\d{8}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }
    
    func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}



import UIKit
import FirebaseFirestore
class AddTechnician: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var txtUserID: UITextField!
    @IBOutlet weak var txtFullName: UITextField!
    @IBOutlet weak var txtEmailAddress: UITextField!
    @IBOutlet weak var txtPhoneNumber: UITextField!
    @IBOutlet weak var btnAddTechnician: UIButton!

    private let db = Firestore.firestore()

    // ✅ Generate once per screen load
    private let userID: String = String(UUID().uuidString.prefix(8)).uppercased()

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTextFields()
        setupUserID()
    }

    // MARK: - Setup Methods


    private func setupTextFields() {
        txtFullName.delegate = self
        txtEmailAddress.delegate = self
        txtPhoneNumber.delegate = self

        txtPhoneNumber.keyboardType = .numberPad

        txtUserID.applySoftBorder()
        txtFullName.applySoftBorder()
        txtEmailAddress.applySoftBorder()
        txtPhoneNumber.applySoftBorder()
    }

    private func setupUserID() {
        txtUserID.text = userID
        txtUserID.isEnabled = false          // ✅ Not editable
        txtUserID.textColor = .secondaryLabel
    }

    // MARK: - Add Technician
    @IBAction func btnAddTechnician(_ sender: Any) {

        let fullName = txtFullName.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = txtEmailAddress.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let phone = txtPhoneNumber.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard validate(fullName: fullName, email: email, phone: phone) else { return }

        let docRef = db.collection("Technicians_Mohammed").document()

        let data: [String: Any] = [
            "userID": userID,
            "name": fullName,
            "email": email,
            "phoneNumber": phone,
            "image": "person.fill"
        ]

        docRef.setData(data) { [weak self] error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert(title: "Error", message: error.localizedDescription)
                return
            }

            let technician = Technician(
                profileImageURL: "person.fill",
                userID: self.userID,
                name: fullName,
                email: email,
                phoneNumber: phone,
                password: nil,
                uid: docRef.documentID
            )

            arrTechnicians.append(technician)

            self.showAlert(title: "Success", message: "Technician added successfully!") {
                self.navigationController?.popViewController(animated: true)
            }
        }
    }

    // MARK: - Validation

    private func validate(fullName: String, email: String, phone: String) -> Bool {

        if fullName.isEmpty {
            showAlert(title: "Validation Error", message: "Full name is required")
            return false
        }

        if !isValidEmail(email) {
            showAlert(title: "Validation Error", message: "Invalid email address")
            return false
        }

        if !isValidBahrainPhone(phone) {
            showAlert(title: "Validation Error", message: "Phone number must be 8 digits")
            return false
        }

        return true
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func isValidBahrainPhone(_ phone: String) -> Bool {
        let regex = "^\\d{8}$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: phone)
    }

    // MARK: - Alerts

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func showAlert(title: String, message: String, onOK: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOK() })
        present(alert, animated: true)
    }

    // MARK: - Keyboard Navigation

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == txtFullName {
            txtEmailAddress.becomeFirstResponder()
        } else if textField == txtEmailAddress {
            txtPhoneNumber.becomeFirstResponder()
        } else {
            textField.resignFirstResponder()
        }
        return true
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
