//
//  EditProfileTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 27/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class EditProfileTableViewController: UITableViewController {

    @IBOutlet weak var fullNameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var phoneTextField: UITextField!

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInfo()
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

            DispatchQueue.main.async {
                self.fullNameTextField.text = name
                self.phoneTextField.text = (phoneNumber == "0") ? "" : phoneNumber
            }
        }
    }

    @IBAction func saveChangesTapped(_ sender: UIButton) {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        let name = fullNameTextField.text ?? ""
        let phone = phoneTextField.text ?? ""

        db.collection("users").document(uid).updateData([
            "name": name,
            "phone": phone
        ]) { [weak self] error in
            if let error = error {
                self?.showAlert("Error", error.localizedDescription)
            } else {
                self?.showAlert("Saved", "Profile updated successfully.")
            }
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

