//
//  Requests.swift
//  QuickFix
//
//  Add New Request screen (Firestore)
//  ✅ Campus is a UIButton (ActionSheet picker)
//  ✅ userId is stored as NUMBER in requests
//     - We fetch numeric userId from: users/{firebaseUid}.userId
//  ✅ status = "pending"
//  ✅ createdAt = Timestamp(date: Date())
//  ✅ Optional image picker (NO Cloudinary / NO external upload)
//
//  Firestore required structure:
//  users (collection)
//    {uid} (document id = Firebase Auth uid string)
//      userId : Int   <-- MUST EXIST
//
//  requests (collection)
//    autoId
//      userId : Int
//      title : String
//      campus : String
//      building : Int
//      classroom : Int
//      problemDescription : String
//      status : String
//      createdAt : Timestamp
//      imageUrl : String? (optional)
//
//  NOTE: This file only picks an image locally. It does NOT upload it anywhere.
//  If you want image upload later, tell me and we’ll do Firebase Storage.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class Requests: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var campusTextField: UIButton!
    @IBOutlet weak var buildingTextField: UITextField!
    @IBOutlet weak var classroomTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextField!
    @IBOutlet weak var previewImageView: UIImageView? // optional

    // MARK: - Campus options
    private let campusOptions = ["Campus A", "Campus B", "Dilmonia"]

    // MARK: - Firebase
    private let db = Firestore.firestore()

    // MARK: - State
    private var pickedImage: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    // MARK: - UI

    private func setupUI() {
        // default campus title
        if (campusTextField.title(for: .normal) ?? "").isEmpty {
            campusTextField.setTitle("Select Campus", for: .normal)
        }

        // preview image styling
        previewImageView?.contentMode = .scaleAspectFill
        previewImageView?.layer.cornerRadius = 12
        previewImageView?.layer.masksToBounds = true

        // dismiss keyboard
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Get numeric userId (REQUIRED)
    // Reads: users/{uid}.userId (Int)
    private func fetchNumericUserId() async throws -> Int {
        guard let uid = Auth.auth().currentUser?.uid else {
            throw NSError(domain: "Auth", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Please login first."])
        }

        let snap = try await db.collection("users").document(uid).getDocument()
        guard let data = snap.data() else {
            throw NSError(domain: "User", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "User profile not found in Firestore (users/{uid})."])
        }

        // Sometimes numbers come back as Int, sometimes as Int64 / Double depending on how written.
        if let n = data["userId"] as? Int { return n }
        if let n = data["userId"] as? Int64 { return Int(n) }
        if let n = data["userId"] as? Double { return Int(n) }

        throw NSError(domain: "User", code: 0,
                      userInfo: [NSLocalizedDescriptionKey: "Numeric userId not found. Add users/{uid}.userId (Number)."])
    }

    // MARK: - Campus (UIButton)
    @IBAction func campusButtonTapped(_ sender: UIButton) {
        let sheet = UIAlertController(title: "Select Campus", message: nil, preferredStyle: .actionSheet)

        campusOptions.forEach { campus in
            sheet.addAction(UIAlertAction(title: campus, style: .default) { [weak self] _ in
                self?.campusTextField.setTitle(campus, for: .normal)
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        // iPad safe
        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(sheet, animated: true)
    }

    // MARK: - Submit
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                // 1) fetch numeric userId
                let numericUserId = try await fetchNumericUserId()

                // 2) read inputs
                let campus = (campusTextField.title(for: .normal) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let buildingText = (buildingTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let classroomText = (classroomTextField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                let desc = (descriptionTextView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

                // 3) validate + convert building/classroom to Int
                let building = try parseNumberField(buildingText, fieldName: "Building")
                let classroom = try parseNumberField(classroomText, fieldName: "Classroom")
                try validate(campus: campus, desc: desc)

                // 4) Save to Firestore
                try await saveToFirestore(
                    userId: numericUserId,
                    campus: campus,
                    building: building,
                    classroom: classroom,
                    desc: desc,
                    imageUrl: nil // no upload in this version
                )

                await MainActor.run {
                    sender.isEnabled = true
                    self.view.isUserInteractionEnabled = true
                    self.navigationController?.popViewController(animated: true)
                }

            } catch {
                await MainActor.run {
                    sender.isEnabled = true
                    self.view.isUserInteractionEnabled = true
                    self.showAlert(title: "Error", message: error.localizedDescription)
                }
            }
        }
    }

    // MARK: - Upload image (LOCAL PICK ONLY)
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        presentImagePicker()
    }

    // MARK: - Validation helpers

    private func validate(campus: String, desc: String) throws {
        let campusIsValid = !campus.isEmpty && campus != "Select Campus"
        guard campusIsValid, !desc.isEmpty else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Please fill all fields before submitting."])
        }
    }

    private func parseNumberField(_ text: String, fieldName: String) throws -> Int {
        guard !text.isEmpty else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "\(fieldName) is required."])
        }
        guard let n = Int(text) else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "\(fieldName) must be a number."])
        }
        return n
    }

    // MARK: - Firestore save

    private func saveToFirestore(
        userId: Int,
        campus: String,
        building: Int,
        classroom: Int,
        desc: String,
        imageUrl: String?
    ) async throws {

        let payload: [String: Any] = [
            "userId": userId,                       // ✅ NUMBER
            "title": desc,                          // used in MyRequests list (you can add a title field later)
            "campus": campus,
            "building": building,                   // ✅ NUMBER
            "classroom": classroom,                 // ✅ NUMBER
            "problemDescription": desc,
            "imageUrl": imageUrl as Any,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("requests").addDocument(data: payload)
    }

    // MARK: - Image Picker

    private func presentImagePicker() {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            showAlert(title: "Error", message: "Photo Library not available.")
            return
        }

        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - Alert

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension Requests: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(
        _ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]
    ) {
        picker.dismiss(animated: true)

        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        pickedImage = img
        previewImageView?.image = img
    }
}
