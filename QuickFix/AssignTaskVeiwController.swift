//
//  AssignTaskVeiwController.swift
//  QuickFix
//
//  Created by BP-36-212-02 on 25/12/2025.
//

import Foundation
import UIKit

// Assign Task screen (Technician List)
// Storyboard:
// - VC class = AssignTaskViewController
// - TableView outlet connected
// - Prototype cell identifier = "TechCell"
// - Inside the cell you already have: image view + label(s)

final class AssignTaskViewController: UIViewController {

    
    @IBOutlet var tableView: UITableView!
    
    // MARK: - Demo data (replace with Firestore later)
    struct Technician {
        let name: String
        let email: String
    }

    private var technicians: [Technician] = [
        .init(name: "Salman Ali", email: "Salman_Ali@polytechnic.bh"),
        .init(name: "Ammar Hassan", email: "Ammar_Hassan@polytechnic.bh"),
        .init(name: "Miqdad Murtadah", email: "Miqdad_Murtadah@polytechnic.bh"),
        .init(name: "Ali Salman", email: "man_Ali@polytechnic.bh"),
        .init(name: "Ali Ammar Hassan", email: "Ali_Hassan@polytechnic.bh"),
        .init(name: "Murtadah Hassan", email: "Murtadah@polytechnic.bh")
    ]

    private var filtered: [Technician] = []

    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()

        filtered = technicians

        setupNavBar()
        setupSearch()
        setupTableUI()
    }

    // MARK: - UI

    private func setupNavBar() {
        title = "Technician List"

        let barColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)

        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = barColor
        appearance.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]

        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white
    }

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchResultsUpdater = self

        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false

        // Make search bar background look clean
        searchController.searchBar.searchTextField.backgroundColor = .white
        searchController.searchBar.searchTextField.layer.cornerRadius = 10
        searchController.searchBar.searchTextField.layer.masksToBounds = true
    }

    private func setupTableUI() {
        view.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)

        tableView.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 20, right: 0)

        tableView.dataSource = self
        tableView.delegate = self
    }

    // MARK: - Cell styling helpers

    private func styleCard(_ card: UIView) {
        card.backgroundColor = .white
        card.layer.cornerRadius = 12
        card.layer.masksToBounds = true
    }

    private func styleAvatar(_ imageView: UIImageView) {
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = imageView.bounds.width / 2
        imageView.backgroundColor = UIColor(red: 0.86, green: 0.91, blue: 0.98, alpha: 1)
    }

    private func makeAvatarImage() -> UIImage? {
        // uses your SF symbol: person.crop.circle.fill
        let config = UIImage.SymbolConfiguration(pointSize: 34, weight: .regular)
        return UIImage(systemName: "person.crop.circle.fill", withConfiguration: config)
    }
}

// MARK: - UITableViewDataSource
extension AssignTaskViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        filtered.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // Your storyboard prototype identifier
        let cell = tableView.dequeueReusableCell(withIdentifier: "TechCell", for: indexPath)
        let item = filtered[indexPath.row]

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        // We will create a card view INSIDE contentView to guarantee spacing (reuse-safe)
        let cardTag = 7001
        cell.contentView.viewWithTag(cardTag)?.removeFromSuperview()

        let card = UIView()
        card.tag = cardTag
        styleCard(card)
        cell.contentView.addSubview(card)

        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor, constant: 16),
            card.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor, constant: -16),
            card.topAnchor.constraint(equalTo: cell.contentView.topAnchor, constant: 8),
            card.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor, constant: -8)
        ])

        // Build row UI (avatar + name + email)
        let avatar = UIImageView(image: makeAvatarImage())
        avatar.translatesAutoresizingMaskIntoConstraints = false

        let nameLabel = UILabel()
        nameLabel.text = item.name
        nameLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        nameLabel.textColor = .label
        nameLabel.translatesAutoresizingMaskIntoConstraints = false

        let emailLabel = UILabel()
        emailLabel.text = item.email
        emailLabel.font = .systemFont(ofSize: 12, weight: .regular)
        emailLabel.textColor = .secondaryLabel
        emailLabel.translatesAutoresizingMaskIntoConstraints = false

        card.addSubview(avatar)
        card.addSubview(nameLabel)
        card.addSubview(emailLabel)

        NSLayoutConstraint.activate([
            avatar.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 16),
            avatar.centerYAnchor.constraint(equalTo: card.centerYAnchor),
            avatar.widthAnchor.constraint(equalToConstant: 44),
            avatar.heightAnchor.constraint(equalToConstant: 44),

            nameLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            nameLabel.topAnchor.constraint(equalTo: card.topAnchor, constant: 14),

            emailLabel.leadingAnchor.constraint(equalTo: avatar.trailingAnchor, constant: 12),
            emailLabel.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -16),
            emailLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 4),
            emailLabel.bottomAnchor.constraint(lessThanOrEqualTo: card.bottomAnchor, constant: -14)
        ])

        // Avatar round after layout
        DispatchQueue.main.async { [weak avatar] in
            guard let avatar else { return }
            self.styleAvatar(avatar)
        }

        return cell
    }
}

// MARK: - UITableViewDelegate
extension AssignTaskViewController: UITableViewDelegate {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        78
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let tech = filtered[indexPath.row]
        let alert = UIAlertController(title: "Assign Task", message: "Assign to \(tech.name)?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Assign", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - Search
extension AssignTaskViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        let q = (searchController.searchBar.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if q.isEmpty {
            filtered = technicians
        } else {
            filtered = technicians.filter {
                $0.name.lowercased().contains(q) || $0.email.lowercased().contains(q)
            }
        }
        tableView.reloadData()
    }
}
