//
//  EditProfileTableViewController.swift
//  QuickFix
//
//  Created by Faisal Alsinini on 27/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore
import Cloudinary

final class EditProfileTableViewController: UITableViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!


    private let db = Firestore.firestore()
    
    private let cloudName = "dzthj3w6v"
    private let unsignedUploadPreset = "profile"

    private lazy var cloudinary: CLDCloudinary = {
        let config = CLDConfiguration(cloudName: cloudName, secure: true)
        return CLDCloudinary(configuration: config)
    }()

    private var uploadedProfileImageURL: String?
    private var selectedProfileImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupProfileImageTap()
        loadUserInfo()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        profileImageView.layoutIfNeeded()

        let side = min(profileImageView.bounds.width, profileImageView.bounds.height)
        profileImageView.layer.cornerRadius = side / 2
        profileImageView.layer.masksToBounds = true
    }


    private func loadUserInfo() {
        guard let user = Auth.auth().currentUser else { return }
        let uid = user.uid

        emailTextField.text = user.email ?? ""

        db.collection("users").document(uid).getDocument { [weak self] snap, error in
            guard let self = self else { return }
            if let error = error {
                print("Firestore error:", error.localizedDescription)
                return
            }

            let data = snap?.data() ?? [:]

            let name = data["name"] as? String ?? ""
            let phone = data["phone"] as? String ?? ""

            let phoneNumber =
            phone.isEmpty ? String((data["phone"] as? Int) ?? Int((data["phone"] as? Int64) ?? 0)) : phone

            let profileURL = data["profileImageURL"] as? String ?? ""

            DispatchQueue.main.async {
                self.fullNameTextField.text = name
                self.phoneTextField.text = (phoneNumber == "0") ? "" : phoneNumber

                if !profileURL.isEmpty {
                    self.uploadedProfileImageURL = profileURL
                    self.loadImage(from: profileURL)
                }
            }
        }
    }
    
    private func setupProfileImageTap() {
        profileImageView.isUserInteractionEnabled = true
        profileImageView.clipsToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(profileImageTapped))
        profileImageView.addGestureRecognizer(tap)
    }

    @objc private func profileImageTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let image = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.profileImageView.image = image
            }
        }.resume()
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
        ) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                self.showAlert("Upload Error", error.localizedDescription)
                return
            }

            guard let secureUrl = result?.secureUrl else {
                self.showAlert("Upload Error", "No URL returned.")
                return
            }

            self.uploadedProfileImageURL = secureUrl

            completion(secureUrl)
        }
    }


    private func saveProfileImageURLToFirestore(_ url: String) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        db.collection("users").document(uid).setData(
            ["profileImageURL": url],
            merge: true
        ) { [weak self] error in
            if let error = error {
                self?.showAlert("Save Error", error.localizedDescription)
            }
        }
    }


    @IBAction func saveChangesTapped(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let name = fullNameTextField.text ?? ""
        let phone = phoneTextField.text ?? ""

        if let newImage = selectedProfileImage {
            uploadProfileImageToCloudinary(newImage) { [weak self] url in
                guard let self = self else { return }

                let updates: [String: Any] = [
                    "name": name,
                    "phone": phone,
                    "profileImageURL": url
                ]

                self.db.collection("users").document(uid).updateData(updates) { [weak self] error in
                    if let error = error {
                        self?.showAlert("Error", error.localizedDescription)
                    } else {
                        self?.selectedProfileImage = nil
                        self?.showAlert("Saved", "Profile updated successfully.")
                    }
                }
            }
        } else {
            var updates: [String: Any] = [
                "name": name,
                "phone": phone
            ]

            if let url = uploadedProfileImageURL, !url.isEmpty {
                updates["profileImageURL"] = url
            }

            db.collection("users").document(uid).updateData(updates) { [weak self] error in
                if let error = error {
                    self?.showAlert("Error", error.localizedDescription)
                } else {
                    self?.showAlert("Saved", "Profile updated successfully.")
                }
            }
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
}

extension EditProfileTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

        let pickedImage =
            (info[.editedImage] as? UIImage) ??
            (info[.originalImage] as? UIImage)

        guard let image = pickedImage else {
            picker.dismiss(animated: true)
            return
        }

        profileImageView.image = image
        picker.dismiss(animated: true)

        selectedProfileImage = image
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
