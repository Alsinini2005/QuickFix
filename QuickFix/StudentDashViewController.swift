
import UIKit
import FirebaseAuth
import FirebaseFirestore

final class StudentDashViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)

    @IBOutlet private weak var welcomeLabel: UILabel!
    @IBOutlet private weak var quickActionsLabel: UILabel!
    @IBOutlet private weak var viewRecentButton: UIButton!
    @IBOutlet weak var profileImageView: UIImageView!


    override func viewDidLoad() {
        super.viewDidLoad()
        loadProfileImageFromFirebase()
    }

    // MARK: - Firebase (Image only)
    private func loadProfileImageFromFirebase() {
        guard let uid = Auth.auth().currentUser?.uid else { return }

        Firestore.firestore()
            .collection("users")
            .document(uid)
            .getDocument { [weak self] snapshot, error in
                guard let self else { return }
                guard
                    let data = snapshot?.data(),
                    let urlString = data["profileImageUrl"] as? String,
                    let url = URL(string: urlString)
                else {
                    return
                }

                URLSession.shared.dataTask(with: url) { data, _, _ in
                    guard let data, let image = UIImage(data: data) else { return }
                    DispatchQueue.main.async {
                        self.profileImageView.image = image
                    }
                }.resume()
            }
    }
}
