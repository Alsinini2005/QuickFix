//
//  ChangePasswordTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 27/12/2025.
//

import UIKit
import FirebaseAuth

final class ChangePasswordTableViewController: UITableViewController {

    @IBOutlet weak var oldPasswordTextField: UITextField!
    @IBOutlet weak var newPasswordTextField: UITextField!
    @IBOutlet weak var confirmPasswordTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func saveNewPasswordTapped(_ sender: UIButton) {
        let oldPass = oldPasswordTextField.text ?? ""
        let newPass = newPasswordTextField.text ?? ""
        let confirm = confirmPasswordTextField.text ?? ""


        guard !oldPass.isEmpty else {
            showAlert(title: "Missing Old Password", message: "Please enter your old password.")
            return
        }

        guard !newPass.isEmpty else {
            showAlert(title: "Missing New Password", message: "Please enter a new password.")
            return
        }

        guard newPass.count >= 6 else {
            showAlert(title: "Weak Password", message: "New password must be at least 6 characters.")
            return
        }

        guard newPass == confirm else {
            showAlert(title: "Password Mismatch", message: "New password and confirm password do not match.")
            return
        }

        guard let user = Auth.auth().currentUser,
              let email = user.email else {
            showAlert(title: "Error", message: "No logged in user.")
            return
        }

        let credential = EmailAuthProvider.credential(withEmail: email, password: oldPass)

        user.reauthenticate(with: credential) { [weak self] _, error in
            if let error = error {
                self?.showAlert(title: "Old Password Incorrect", message: error.localizedDescription)
                return
            }

            user.updatePassword(to: newPass) { [weak self] error in
                if let error = error {
                    self?.showAlert(title: "Update Failed", message: error.localizedDescription)
                    return
                }

                self?.clearFields()
                self?.showAlert(title: "Success", message: "Your password has been updated.") {
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func clearFields() {
        oldPasswordTextField.text = ""
        newPasswordTextField.text = ""
        confirmPasswordTextField.text = ""
    }

    private func showAlert(title: String, message: String, onOK: (() -> Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in onOK?() })
        present(alert, animated: true)
    }
}

