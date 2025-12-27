//
//  LoginTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 23/12/2025.
//
import FirebaseAuth
import FirebaseFirestore
import UIKit


class LoginTableViewController: UITableViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!

    @IBOutlet weak var emailErrorLabel: UILabel!
    @IBOutlet weak var passwordErrorLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        hideErrors()
    }

    private func hideErrors() {
        emailErrorLabel.isHidden = true
        passwordErrorLabel.isHidden = true
        emailErrorLabel.text = ""
        passwordErrorLabel.text = ""
    }

    private func isValidEmail(_ email: String) -> Bool {
        let pattern = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return email.range(of: pattern, options: .regularExpression) != nil
    }
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {
    
    hideErrors()

    let email = emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let password = passwordTextField.text ?? ""

    var isValid = true

    if email.isEmpty {
        emailErrorLabel.text = "Email is required"
        emailErrorLabel.isHidden = false
        isValid = false
    } else if !isValidEmail(email) {
        emailErrorLabel.text = "Email format is not valid"
        emailErrorLabel.isHidden = false
        isValid = false
    }

    if password.isEmpty {
        passwordErrorLabel.text = "Password is required"
        passwordErrorLabel.isHidden = false
        isValid = false
    }

        guard isValid else { return }

        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            if let error = error as NSError? {
                self?.handleAuthError(error)
                return
            }

            guard let uid = result?.user.uid else { return }
            self?.fetchUserTypeAndNavigate(uid: uid, sender: sender)
        }
    }
    
    private func fetchUserTypeAndNavigate(uid: String, sender: UIButton) {

        let db = Firestore.firestore()

        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            if let error = error {
                self?.showAlert(title: "Error", message: error.localizedDescription)
                return
            }

            guard let data = snapshot?.data(),
                  let usertype = data["usertype"] as? String else {
                self?.showAlert(title: "Error", message: "User type not found")
                return
            }

            self?.routeUser(by: usertype)
        }
    }

    private func routeUser(by userType: String) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)

        let vcID: String
        switch userType.lowercased() {
        case "admin":
            vcID = "AdminFlow"
        case "technician":
            vcID = "TechnicianFlow"
        case "user":
            vcID = "UserFlow"
        default:
            showAlert(title: "Error", message: "Unknown user type: \(userType)")
            return
        }

        let vc = storyboard.instantiateViewController(withIdentifier: vcID)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }


    private func handleAuthError(_ error: NSError) {

    let code = AuthErrorCode(rawValue: error.code)

    switch code {
    case .wrongPassword, .invalidCredential:
        showAlert(title: "Login Failed", message: "Email or password is incorrect.")
    default:
        showAlert(title: "Login Failed", message: error.localizedDescription)
    }
    }

    func showAlert(title: String, message: String) {
    let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "OK", style: .default))
    present(alert, animated: true)
    }
}

