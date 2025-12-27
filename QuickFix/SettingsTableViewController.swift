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

    private var currentUserType: String = "user"
    
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        loadUserInfo()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadUserInfo()
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

            let fullName = data["name"] as? String ?? "No Name"
            let userType = (data["usertype"] as? String ?? "user").capitalized

            DispatchQueue.main.async {
                self.nameLabel.text = fullName
                self.userTypeLabel.text = userType
                
                self.currentUserType = userType
                self.tableView.reloadData()
            }
        }
    }
    private var isAdmin: Bool { currentUserType == "Admin" }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 1 && !isAdmin { return nil }   // Preference section
        return super.tableView(tableView, titleForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 1 && !isAdmin { return nil }
        return super.tableView(tableView, viewForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 1 && !isAdmin { return CGFloat.leastNormalMagnitude }
        return super.tableView(tableView, heightForHeaderInSection: section)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 1 && !isAdmin { return 0 }
        return super.tableView(tableView, heightForRowAt: indexPath)
    }

    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && !isAdmin {
            cell.isHidden = true
            cell.isUserInteractionEnabled = false
        } else {
            cell.isHidden = false
            cell.isUserInteractionEnabled = true
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

            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewController(
                withIdentifier: "LoginTableViewController"
            )

            loginVC.modalPresentationStyle = .fullScreen

            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController = loginVC
                window.makeKeyAndVisible()
            }

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
