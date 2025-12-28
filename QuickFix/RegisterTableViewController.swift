//
//  RegisterTableViewController.swift
//  QuickFix
//
//  Created by BP-36-201-06 on 28/12/2025.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class RegisterTableViewController: UITableViewController {

    @IBOutlet private weak var fullNameTextField: UITextField!
    @IBOutlet private weak var emailTextField: UITextField!
    @IBOutlet private weak var passwordTextField: UITextField!
    @IBOutlet private weak var confirmPasswordTextField: UITextField!

    @IBOutlet private weak var fullNameErrorLabel: UILabel!
    @IBOutlet private weak var emailErrorLabel: UILabel!
    @IBOutlet private weak var passwordErrorLabel: UILabel!
    @IBOutlet private weak var confirmPasswordErrorLabel: UILabel!

    @IBOutlet private weak var createAccountButton: UIButton!

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        clearAllErrors()
    }

    
    @IBAction private func createAccountTapped(_ sender: UIButton) {
        clearAllErrors()

        let fullName = fullNameTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let password = passwordTextField.text ?? ""
        let confirm = confirmPasswordTextField.text ?? ""

        guard validate(fullName: fullName, email: email, password: password, confirm: confirm) else {
            tableView.beginUpdates()
            tableView.endUpdates()
            return
        }

        createAccountButton.isEnabled = false

        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            self.createAccountButton.isEnabled = true

            if let error = error {
                self.handleFirebaseError(error)
                self.tableView.beginUpdates()
                self.tableView.endUpdates()
                return
            }

            guard let uid = result?.user.uid else { return }

            let userData: [String: Any] = [
                "name": fullName,
                "phone": "",          // create empty now for future Edit Profile
                "usertype": "user"
            ]

            self.db.collection("users").document(uid).setData(userData, merge: true) { err in
                if let err = err {
                    self.showAlert("Error", err.localizedDescription)
                    return
                }

                // ✅ Show success alert then go back to Login
                self.showAlert(title: "Success", message: "Account created successfully!") { [weak self] in
                    self?.navigationController?.popViewController(animated: true)
                }
            }
        }
    }

    private func validate(fullName: String, email: String, password: String, confirm: String) -> Bool {
        var valid = true

        if fullName.isEmpty {
            fullNameErrorLabel.text = "Full name is required"
            valid = false
        }

        if !isValidEmail(email) {
            emailErrorLabel.text = "Invalid email address"
            valid = false
        }

        if password.count < 6 {
            passwordErrorLabel.text = "Password must be at least 6 characters"
            valid = false
        }

        if confirm != password {
            confirmPasswordErrorLabel.text = "Passwords do not match"
            valid = false
        }

        return valid
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^\S+@\S+\.\S+$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }

    private func clearAllErrors() {
        fullNameErrorLabel.text = ""
        emailErrorLabel.text = ""
        passwordErrorLabel.text = ""
        confirmPasswordErrorLabel.text = ""
    }

    private func handleFirebaseError(_ error: Error) {
        let nsError = error as NSError

        let authCode = AuthErrorCode(rawValue: nsError.code)

        switch authCode {
        case .emailAlreadyInUse:
            emailErrorLabel.text = "Email already in use"
        case .invalidEmail:
            emailErrorLabel.text = "Invalid email"
        case .weakPassword:
            passwordErrorLabel.text = "Weak password"
        default:
            showAlert("Register Failed", error.localizedDescription)
        }
    }

    private func showAlert(_ title: String, _ message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    private func showAlert(title: String, message: String, onOK: @escaping () -> Void) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in
            onOK()
        })
        present(alert, animated: true)
    }
}

extension RegisterTableViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        switch textField {
        case fullNameTextField:
            emailTextField.becomeFirstResponder()
        case emailTextField:
            passwordTextField.becomeFirstResponder()
        case passwordTextField:
            confirmPasswordTextField.becomeFirstResponder()
        default:
            textField.resignFirstResponder()
        }
        return true
    }
}
