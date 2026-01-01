//
//  TasksTableViewCell.swift
//  QuickFix
//
//  Created by BP-36-212-04 on 01/01/2026.
//

import UIKit

final class TasksTableViewCell: UITableViewCell {
    @IBOutlet weak var taskImageView: UIImageView!
        @IBOutlet weak var taskNameLabel: UILabel!
        @IBOutlet weak var taskNumberLabel: UILabel!

        override func awakeFromNib() {
            super.awakeFromNib()
            taskImageView.layer.cornerRadius = 8
            taskImageView.clipsToBounds = true
        }

        func configure(name: String, number: String, imageURL: String?) {
            taskNameLabel.text = name
            taskNumberLabel.text = number
            taskImageView.image = UIImage(systemName: "photo")

            guard let imageURL, let url = URL(string: imageURL) else { return }
            URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
                guard let self, let data, let img = UIImage(data: data) else { return }
                DispatchQueue.main.async { self.taskImageView.image = img }
            }.resume()
        }
}
