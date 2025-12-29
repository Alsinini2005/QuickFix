import UIKit
import FirebaseFirestore

final class DashboardViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var pendingCardView: UIView!
    @IBOutlet weak var onProcessCardView: UIView!
    @IBOutlet weak var monthlyCardView: UIView!

    // These are the "0" labels
    @IBOutlet private weak var pendingCountLabel: UILabel!
    @IBOutlet private weak var inProgressCountLabel: UILabel!
    @IBOutlet private weak var completedThisMonthLabel: UILabel!

    // MARK: - Firebase
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        styleCards()
        startListeningCountsForAdmin()
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
        v.layer.shadowRadius = 0
        v.layer.shadowOffset = .zero
        v.layer.shadowColor = nil
    }

    // MARK: - Firestore counting (ADMIN: all requests)
    private func startListeningCountsForAdmin() {
        listener?.remove()

        // Admin: no technician filter, listen to ALL requests
        let query = db.collection("requests")

        listener = query.addSnapshotListener { [weak self] snapshot, error in
            guard let self else { return }

            if let error {
                print("Admin Dashboard listen error:", error)
                return
            }

            let docs = snapshot?.documents ?? []

            var pending = 0
            var inProgress = 0
            var completedThisMonth = 0

            let now = Date()
            let cal = Calendar.current
            let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: now)) ?? now
            let nextMonth = cal.date(byAdding: .month, value: 1, to: monthStart) ?? now

            for d in docs {
                let data = d.data()
                let status = (data["status"] as? String) ?? "pending"

                switch status {
                case "pending":
                    pending += 1

                case "in_progress":
                    inProgress += 1

                case "completed":
                    // ✅ best: use completedAt if exists
                    if let ts = data["completedAt"] as? Timestamp {
                        let date = ts.dateValue()
                        if date >= monthStart && date < nextMonth {
                            completedThisMonth += 1
                        }
                    } else if let ts = data["createdAt"] as? Timestamp {
                        // fallback: if you don't store completedAt yet
                        let date = ts.dateValue()
                        if date >= monthStart && date < nextMonth {
                            completedThisMonth += 1
                        }
                    }

                default:
                    break
                }
            }

            self.pendingCountLabel.text = "\(pending)"
            self.inProgressCountLabel.text = "\(inProgress)"
            self.completedThisMonthLabel.text = "\(completedThisMonth)"
        }
    }
}
