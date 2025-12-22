//
//  SettingsTableViewController.swift
//  QuickFix
//
//  Created by BP-36-212-03 on 22/12/2025.
//



import UIKit
import FirebaseAuth
import FirebaseFirestore

final class SettingsTableViewController: UITableViewController {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var userTypeLabel: UILabel!

    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo() // refresh when coming back from Edit Profile
    }

    private func loadUserInfo() {
        guard let uid = Auth.auth().currentUser?.uid else {
            nameLabel.text = "Guest"
            userTypeLabel.text = "Not signed in"
            return
        }

        db.collection("users").document(uid).getDocument { [weak self] snap, error in
            guard let self = self else { return }
            if let error = error {
                print("Firestore error:", error.localizedDescription)
                return
            }

            let data = snap?.data() ?? [:]
            let fullName = data["fullName"] as? String ?? "No Name"
            let userType = data["userType"] as? String ?? "User"

            DispatchQueue.main.async {
                self.nameLabel.text = fullName
                self.userTypeLabel.text = userType
            }
        }
    }

    @IBAction func logoutTapped(_ sender: UIButton) {
        let alert = UIAlertController(
            title: "Log Out",
            message: "Are you sure you want to log out?",
            preferredStyle: .alert
        )

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive) { _ in
            self.doLogout()
        })

        present(alert, animated: true)
    }

    private func doLogout() {
        do {
            try Auth.auth().signOut()
            navigationController?.popToRootViewController(animated: true)
        } catch {
            let alert = UIAlertController(
                title: "Error",
                message: "Logout failed: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
        }
    }
}
