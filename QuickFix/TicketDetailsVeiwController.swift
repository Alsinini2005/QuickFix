import UIKit
import FirebaseFirestore

final class TicketDetailsViewController: UIViewController {

    // MARK: - Passed from previous screen
    var requestId: String?

    // MARK: - Outlets (KEEP THESE)
    @IBOutlet private weak var containerView: UIView!
    @IBOutlet private weak var stackView: UIStackView!

    @IBOutlet private weak var imageTitleLabel: UILabel!
    @IBOutlet private weak var ticketImageView: UIImageView!
    @IBOutlet private weak var assignButton: UIButton!

    @IBOutlet private weak var ticketNameLabel: UILabel!
    @IBOutlet private weak var campusLabel: UILabel!
    @IBOutlet private weak var buildingLabel: UILabel!
    @IBOutlet private weak var statusLabel: UILabel!
    @IBOutlet private weak var createdLabel: UILabel!

    @IBOutlet private weak var ticketNameTitle: UILabel!
    @IBOutlet private weak var campusTitle: UILabel!
    @IBOutlet private weak var buildingTitle: UILabel!
    @IBOutlet private weak var statusTitle: UILabel!
    @IBOutlet private weak var createdTitle: UILabel!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var imageTask: URLSessionDataTask?

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()

        guard let id = requestId, !id.isEmpty else {
            print("❌ TicketDetails: requestId not set")
            return
        }

        startListening(docId: id)
    }

    deinit {
        listener?.remove()
        imageTask?.cancel()
    }

    // MARK: - UI
    private func setupUI() {
        title = "Ticket Details"

        view.backgroundColor = UIColor(red: 245/255, green: 246/255, blue: 248/255, alpha: 1)

        containerView.backgroundColor = .white
        containerView.layer.cornerRadius = 12
        containerView.layer.masksToBounds = true

        stackView.spacing = 0

        ticketImageView.backgroundColor = UIColor(white: 0.95, alpha: 1)
        ticketImageView.layer.cornerRadius = 12
        ticketImageView.layer.masksToBounds = true
        ticketImageView.contentMode = .scaleAspectFill

        assignButton.layer.cornerRadius = 10
    }

    // MARK: - Firestore
    private func startListening(docId: String) {
        listener?.remove()

        listener = db.collection("StudentRepairRequests")
            .document(docId)
            .addSnapshotListener { [weak self] snap, error in
                guard let self else { return }

                if let error {
                    print("❌ Firestore error:", error.localizedDescription)
                    return
                }

                guard let data = snap?.data() else {
                    print("❌ No data for document:", docId)
                    return
                }

                self.applyData(data)
            }
    }

    private func applyData(_ data: [String: Any]) {

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

        let classroomText: String
        if let c = data["classroom"] as? Int {
            classroomText = "\(c)"
        } else if let c = data["classroom"] as? String {
            classroomText = c
        } else {
            classroomText = ""
        }

        let createdText: String
        if let ts = data["createdAt"] as? Timestamp {
            createdText = dateFormatter.string(from: ts.dateValue())
        } else {
            createdText = "-"
        }

        // Fill labels
        ticketNameLabel.text = title
        campusLabel.text = campus
        buildingLabel.text = classroomText.isEmpty
            ? buildingText
            : "\(buildingText) | Room \(classroomText)"
        statusLabel.text = prettyStatus(statusRaw)
        createdLabel.text = createdText

        // Image
        let imageUrl = (data["imageUrl"] as? String) ?? ""
        loadImage(urlString: imageUrl)
    }

    private func prettyStatus(_ status: String) -> String {
        switch status {
        case "pending": return "Pending"
        case "in_progress": return "In Progress"
        case "completed": return "Completed"
        default: return status
        }
    }

    // MARK: - Image
    private func loadImage(urlString: String) {
        imageTask?.cancel()
        ticketImageView.image = nil

        guard !urlString.isEmpty, let url = URL(string: urlString) else { return }

        imageTask = URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data, let img = UIImage(data: data) else { return }
            DispatchQueue.main.async {
                self?.ticketImageView.image = img
            }
        }
        imageTask?.resume()
    }

    // MARK: - Assign
    @IBAction private func didTapAssign(_ sender: UIButton) {
        performSegue(withIdentifier: "showAssignTask", sender: nil)
    }
}
