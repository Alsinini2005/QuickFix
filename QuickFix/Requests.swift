//
//  AddNewRequestViewController.swift
//  QuickFix
//
//  Add New Request screen
//  ✅ Campus is a UIButton (picker via ActionSheet)
//  ✅ Submit saves to Firestore so it appears in MyRequestsViewController
//     - userId = numeric (read from users/{authUid}.userId)
//     - status = "pending"
//     - createdAt = Timestamp(date: Date())
//  ✅ Optional image upload to Cloudinary (only if configured)
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AddNewRequestViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var campusTextField: UIButton!          // Button title shows selected campus
    @IBOutlet weak var buildingTextField: UITextField!
    @IBOutlet weak var classroomTextField: UITextField!
    @IBOutlet weak var descriptionTextView: UITextField!   // if multiline -> change storyboard to UITextView
    @IBOutlet weak var previewImageView: UIImageView?      // optional

    // MARK: - Campus options
    private let campusOptions = ["Campus A", "Campus B", "Dilmonia"]

    // MARK: - Cloudinary (OPTIONAL)
    // Leave as default if not using Cloudinary.
    private let cloudName = "YOUR_CLOUD_NAME"
    private let uploadPreset = "YOUR_UNSIGNED_PRESET"

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

        // image preview styling
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

    // MARK: - Actions
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                guard let uid = Auth.auth().currentUser?.uid else {
                    await MainActor.run {
                        sender.isEnabled = true
                        self.view.isUserInteractionEnabled = true
                        self.showAlert(title: "Error", message: "Please login first.")
                    }
                    return
                }

                // Firestore schema uses userId as NUMBER -> read from users/{authUid}.userId
                let numericUserId = try await fetchNumericUserId(authUid: uid)

                let campus = campusTextField.title(for: .normal) ?? ""
                let buildingText = buildingTextField.text ?? ""
                let classroomText = classroomTextField.text ?? ""
                let desc = descriptionTextView.text ?? ""

                let building = try parseIntField(buildingText, fieldName: "Building")
                let classroom = try parseIntField(classroomText, fieldName: "Classroom")

                try validate(campus: campus, building: building, classroom: classroom, desc: desc)

                // Optional image upload
                let imageUrl: String? = try await uploadToCloudinaryIfConfigured(image: pickedImage)

                // Save request
                try await saveToFirestore(
                    userId: numericUserId,
                    campus: campus,
                    building: building,
                    classroom: classroom,
                    desc: desc,
                    imageUrl: imageUrl
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

    @IBAction func uploadImageTapped(_ sender: UIButton) {
        presentImagePicker()
    }

    // MARK: - Validation
    private func validate(campus: String, building: Int, classroom: Int, desc: String) throws {
        let campusT = campus.trimmingCharacters(in: .whitespacesAndNewlines)
        let descT = desc.trimmingCharacters(in: .whitespacesAndNewlines)

        let campusIsValid = !campusT.isEmpty && campusT != "Select Campus"

        guard campusIsValid, building > 0, classroom > 0, !descT.isEmpty else {
            throw NSError(
                domain: "Validation",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Please fill all fields before submitting."]
            )
        }
    }

    // MARK: - Firestore
    private func saveToFirestore(
        userId: Int,
        campus: String,
        building: Int,
        classroom: Int,
        desc: String,
        imageUrl: String?
    ) async throws {

        let cleanCampus = campus.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanDesc = desc.trimmingCharacters(in: .whitespacesAndNewlines)

        let payload: [String: Any] = [
            "userId": userId,
            "title": cleanDesc, // using description as title
            "campus": cleanCampus,
            "building": building,
            "classroom": classroom,
            "problemDescription": cleanDesc,
            "imageUrl": imageUrl as Any,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("requests").addDocument(data: payload)
    }

    // MARK: - Cloudinary (optional)
    private func uploadToCloudinaryIfConfigured(image: UIImage?) async throws -> String? {
        guard let image else { return nil }

        if cloudName == "YOUR_CLOUD_NAME" || uploadPreset == "YOUR_UNSIGNED_PRESET" {
            return nil
        }

        guard let data = image.jpegData(compressionQuality: 0.85) else {
            throw NSError(domain: "Cloudinary", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "Failed to encode image."])
        }

        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        // preset
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"upload_preset\"\r\n\r\n")
        body.append("\(uploadPreset)\r\n")

        // file
        body.append("--\(boundary)\r\n")
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n")
        body.append("Content-Type: image/jpeg\r\n\r\n")
        body.append(data)
        body.append("\r\n")
        body.append("--\(boundary)--\r\n")

        request.httpBody = body

        let (respData, resp) = try await URLSession.shared.data(for: request)
        guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            let msg = String(data: respData, encoding: .utf8) ?? "Cloudinary upload failed"
            throw NSError(domain: "Cloudinary", code: 2,
                          userInfo: [NSLocalizedDescriptionKey: msg])
        }

        struct CloudinaryResponse: Decodable { let secure_url: String }
        return try JSONDecoder().decode(CloudinaryResponse.self, from: respData).secure_url
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

    // MARK: - Alerts
    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }

    // MARK: - Helpers (numeric fields)
    private func parseIntField(_ text: String, fieldName: String) throws -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let n = Int(trimmed), n > 0 else {
            throw NSError(
                domain: "Validation",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "\(fieldName) must be a number."]
            )
        }
        return n
    }

    /// Reads numeric userId from Firestore: users/{authUid}.userId
    private func fetchNumericUserId(authUid: String) async throws -> Int {
        let snap = try await db.collection("users").document(authUid).getDocument()
        let data = snap.data() ?? [:]

        if let n = data["userId"] as? Int { return n }
        if let n = data["userId"] as? Int64 { return Int(n) }
        if let n = data["userId"] as? Double { return Int(n) }

        throw NSError(
            domain: "User",
            code: 0,
            userInfo: [NSLocalizedDescriptionKey: "Numeric userId not found in users collection."]
        )
    }
}

// MARK: - UIImagePickerControllerDelegate
extension AddNewRequestViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

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

// MARK: - Data helper
private extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8)!)
    }
}
