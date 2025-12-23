//
//  LoginTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 23/12/2025.
//
import FirebaseAuth
import UIKit

class LoginTableViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBAction func loginButtonTapped(_ sender: UIButton) {

     guard let email = emailTextField.text, !email.isEmpty else
    {
         showAlert(title: "Missing Email", message: "Please enter your email address.")
     return
     }

     guard let password = passwordTextField.text,
    !password.isEmpty else {
         showAlert(title: "Missing Password", message: "Please enter your password.")
     return
     }

     // Sign in with Firebase Authentication
     Auth.auth().signIn(withEmail: email, password: password) {
    [weak self] authResult, error in
     // Handle authentication result
     if let error = error {
     // Sign in failed - show error message
     self?.showAlert(title: "Login Failed", message:
    error.localizedDescription)
     return
     }

     // Sign in successful - navigate to home screen
     self?.performSegue(withIdentifier: "Home", sender:
    sender)
     }
    }
    
    func showAlert(title: String, message: String) {
     let alert = UIAlertController(title: title, message:
    message, preferredStyle: .alert)
     alert.addAction(UIAlertAction(title: "OK", style:
    .default))
     present(alert, animated: true)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
