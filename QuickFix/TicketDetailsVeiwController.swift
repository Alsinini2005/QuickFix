import UIKit
import FirebaseFirestore

final class TicketDetailsViewController: UIViewController {

    // MARK: - MUST be set before opening this screen
    // Pass Firestore document id of the request
    var requestId: String!

    // MARK: - Outlets (connect these)
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var imageTitleLabel: UILabel!
    @IBOutlet private weak var ticketImageView: UIImageView!

    @IBOutlet private weak var assignButton: UIButton!

    // Value labels (right side)
    @IBOutlet private weak var ticketIdLabel: UILabel!
    @IBOutlet private weak var ticketNameLabel: UILabel!
    @IBOutlet private weak var campusLabel: UILabel!
    @IBOutlet private weak var buildingLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!
    @IBOutlet private weak var urgencyLabel: UILabel!

    // Title labels (left side)
    @IBOutlet private weak var ticketIdTitle: UILabel!
    @IBOutlet private weak var ticketNameTitle: UILabel!
    @IBOutlet private weak var campusTitle: UILabel!
    @IBOutlet private weak var buildingTitle: UILabel!
    @IBOutlet private weak var statusTitle: UILabel!
    @IBOutlet private weak var createdTitle: UILabel!
    @IBOutlet private weak var urgencyTitle: UILabel!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavBar()
        styleScreen()

        // safety
        if requestId == nil || requestId.isEmpty {
            print("❌ TicketDetailsViewController: requestId not set")
            return
        }

        startListeningTicket()
    }

    deinit { listener?.remove() }

    // MARK: - Navigation Bar
    private func setupNavBar() {
        title = "Ticket Details"

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

    // MARK: - Styling
    private func styleScreen() {
        view.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)

        // Card
        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true

        // Stack view
        stackView.spacing = 0
        addSeparators()

        // Left titles
        let titleLabels = [
            ticketIdTitle, ticketNameTitle, campusTitle,
            buildingTitle, statusTitle, urgencyTitle, createdTitle
        ]

        titleLabels.forEach {
            $0?.font = .systemFont(ofSize: 13, weight: .semibold)
            $0?.textColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        }

        // Right values
        let valueLabels = [
            ticketIdLabel, ticketNameLabel, campusLabel,
            buildingLabel, statusLabel, urgencyLabel, createdLabel
        ]

        valueLabels.forEach {
            $0?.font = .systemFont(ofSize: 13)
            $0?.textColor = .secondaryLabel
        }

        // Image section
        imageTitleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        imageTitleLabel.textColor = .label

        ticketImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        ticketImageView.layer.cornerRadius = 12
        ticketImageView.layer.masksToBounds = true
        ticketImageView.contentMode = .scaleAspectFill

        // Assign button
        assignButton.backgroundColor = UIColor(red: 44/255, green: 70/255, blue: 92/255, alpha: 1)
        assignButton.setTitleColor(.white, for: .normal)
        assignButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        assignButton.layer.cornerRadius = 10
    }

    // MARK: - Firestore
    private func startListeningTicket() {
        listener?.remove()

        listener = db.collection("requests")
            .document(requestId)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }

                if let error {
                    print("❌ Ticket details listen error:", error)
                    return
                }

                guard let data = snap?.data() else {
                    print("❌ No ticket data for id:", self.requestId ?? "nil")
                    return
                }

                self.applyTicketData(data, docId: snap?.documentID ?? self.requestId)
            }
    }

    private func applyTicketData(_ data: [String: Any], docId: String) {
        // DB fields you showed:
        // title (String), campus (String), building (Int), status (String), createdAt (Timestamp)

        let title = (data["title"] as? String) ?? "-"
        let campus = (data["campus"] as? String) ?? "-"
        let statusRaw = (data["status"] as? String) ?? "pending"

        let buildingText: String
        if let b = data["building"] as? Int {
            buildingText = "\(b)"
        } else if let b = data["building"] as? String {
            buildingText = b
        } else {
            buildingText = "-"
        }

        let createdText: String
        if let ts = data["createdAt"] as? Timestamp {
            createdText = dateFormatter.string(from: ts.dateValue())
        } else {
            createdText = "-"
        }

        // urgency OPTIONAL
        let urgency = (data["urgency"] as? String) ?? "Normal"

        // Fill labels
        ticketIdLabel.text = docId
        ticketNameLabel.text = title
        campusLabel.text = campus
        buildingLabel.text = buildingText
        statusLabel.text = prettyStatus(statusRaw)
        createdLabel.text = createdText
        urgencyLabel.text = urgency

        // image OPTIONAL (imageURL)
        if let urlString = data["imageURL"] as? String, !urlString.isEmpty {
            loadImage(from: urlString)
        } else {
            ticketImageView.image = nil
        }
    }

    private func prettyStatus(_ status: String) -> String {
        switch status {
        case "pending": return "Pending"
        case "in_progress": return "In Progress"
        case "completed": return "Completed"
        default: return status
        }
    }

    private func loadImage(from urlString: String) {
        guard let url = URL(string: urlString) else { return }

        // Simple loader without extra libraries
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let self, let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async { self.ticketImageView.image = img }
        }.resume()
    }

    // MARK: - Separators between rows
    private func addSeparators() {
        for (index, row) in stackView.arrangedSubviews.enumerated() {
            guard index != stackView.arrangedSubviews.count - 1 else { continue }

            let separator = UIView()
            separator.backgroundColor = UIColor.systemGray5
            separator.translatesAutoresizingMaskIntoConstraints = false

            row.addSubview(separator)

            NSLayoutConstraint.activate([
                separator.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 16),
                separator.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -16),
                separator.bottomAnchor.constraint(equalTo: row.bottomAnchor),
                separator.heightAnchor.constraint(equalToConstant: 1)
            ])
        }
    }

    // MARK: - Assign button (optional)
    @IBAction private func didTapAssign(_ sender: UIButton) {
        // put your assign logic / segue here
        print("Assign tapped for request:", requestId ?? "nil")
    }
}
