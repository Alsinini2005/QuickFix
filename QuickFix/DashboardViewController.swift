import UIKit
import FirebaseFirestore

final class DashboardViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet private weak var pendingCardView: UIView!
    @IBOutlet private weak var onProcessCardView: UIView!
    @IBOutlet private weak var monthlyCardView: UIView!

    @IBOutlet private weak var pendingCountLabel: UILabel!
    @IBOutlet private weak var onProcessCountLabel: UILabel!
    @IBOutlet private weak var completedCountLabel: UILabel!

    // Donut placeholder view in storyboard
    @IBOutlet private weak var donutContainerView: UIView!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    // MARK: - Donut
    private let donutView = DonutChartView()

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        applyCardStyles()
        setupDonut()
        startListeningCounts()
    }

    private func applyCardStyles() {
        pendingCardView.applyCardStyle()
        onProcessCardView.applyCardStyle()
        monthlyCardView.applyCardStyle()
    }

    deinit { listener?.remove() }

    // MARK: - Donut
    private func setupDonut() {
        donutView.translatesAutoresizingMaskIntoConstraints = false
        donutContainerView.addSubview(donutView)

        NSLayoutConstraint.activate([
            donutView.leadingAnchor.constraint(equalTo: donutContainerView.leadingAnchor),
            donutView.trailingAnchor.constraint(equalTo: donutContainerView.trailingAnchor),
            donutView.topAnchor.constraint(equalTo: donutContainerView.topAnchor),
            donutView.bottomAnchor.constraint(equalTo: donutContainerView.bottomAnchor)
        ])

        // Initial segments (no setData in your DonutChartView)
        donutView.segments = [
            .init(value: 0, color: .systemRed),
            .init(value: 0, color: .systemOrange),
            .init(value: 0, color: .systemGreen)
        ]
    }
    


    // MARK: - Firestore
    private func startListeningCounts() {
        listener?.remove()

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

                    self.donutView.segments = [
                        .init(value: CGFloat(pending), color: .systemRed),
                        .init(value: CGFloat(inProgress), color: .systemOrange),
                        .init(value: CGFloat(completed), color: .systemGreen)
                    ]
                }
            }
    }
}
