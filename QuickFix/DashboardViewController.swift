import UIKit
import FirebaseFirestore

final class DashboardViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var pendingCardView: UIView!
    @IBOutlet weak var onProcessCardView: UIView!
    @IBOutlet weak var monthlyCardView: UIView!

    // ✅ Add these labels in storyboard + connect
    @IBOutlet weak var pendingCountLabel: UILabel!
    @IBOutlet weak var onProcessCountLabel: UILabel!
    @IBOutlet weak var completedCountLabel: UILabel!

    // ✅ Add a UIView placeholder in storyboard for donut + connect
    @IBOutlet weak var donutContainerView: UIView!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Donut
    private let donutView = DonutChartView()

    override func viewDidLoad() {
        super.viewDidLoad()
        styleCards()
        setupDonut()
        startListeningCounts()
    }

    deinit { listener?.remove() }

    // MARK: - UI
    private func styleCards() {
        applyCardStyle(pendingCardView)
        applyCardStyle(onProcessCardView)
        applyCardStyle(monthlyCardView)
    }

    private func applyCardStyle(_ v: UIView) {
        v.backgroundColor = .white
        v.layer.cornerRadius = 6
        v.layer.borderWidth = 1
        v.layer.borderColor = UIColor.systemGray4.cgColor
        v.layer.masksToBounds = true
        v.layer.shadowOpacity = 0
    }

    private func setupDonut() {
        donutContainerView.backgroundColor = .clear

        donutView.translatesAutoresizingMaskIntoConstraints = false
        donutContainerView.addSubview(donutView)

        NSLayoutConstraint.activate([
            donutView.leadingAnchor.constraint(equalTo: donutContainerView.leadingAnchor),
            donutView.trailingAnchor.constraint(equalTo: donutContainerView.trailingAnchor),
            donutView.topAnchor.constraint(equalTo: donutContainerView.topAnchor),
            donutView.bottomAnchor.constraint(equalTo: donutContainerView.bottomAnchor)
        ])

        // initial
        donutView.setData(pending: 0, inProgress: 0, completed: 0)
    }

    // MARK: - Firestore
    private func startListeningCounts() {
        listener?.remove()

        // Listen to all requests and compute counts locally (simple + reliable)
        listener = db.collection("requests")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    print("Dashboard listen error:", err)
                    return
                }

                let docs = snap?.documents ?? []
                var pending = 0
                var inProgress = 0
                var completed = 0

                for d in docs {
                    let status = (d.data()["status"] as? String) ?? "pending"
                    switch status {
                    case "pending":
                        pending += 1
                    case "in_progress":
                        inProgress += 1
                    case "completed":
                        completed += 1
                    default:
                        break
                    }
                }

                DispatchQueue.main.async {
                    self.pendingCountLabel.text = "\(pending)"
                    self.onProcessCountLabel.text = "\(inProgress)"
                    self.completedCountLabel.text = "\(completed)"

                    self.donutView.setData(pending: pending, inProgress: inProgress, completed: completed)
                }
            }
    }
}
