//
//  Requests.swift
//  QuickFix
//
//  New Request backend (Firestore + Cloudinary)
//  - Submit button saves to Firestore
//  - Optional image upload to Cloudinary
//  - Optional photo picker
//

import UIKit
import FirebaseFirestore

final class Requests: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    
    @IBOutlet weak var campusTextField: UIButton!
   
    @IBOutlet weak var buildingTextField: UITextField!
    
    @IBOutlet weak var classroomTextField: UITextField!
   
    @IBOutlet weak var descriptionTextView: UITextField!
    
    @IBOutlet weak var previewImageView: UIImageView?      // optional

    // MARK: - Config (CHANGE THESE)
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

    private func setupUI() {
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

    // MARK: - Actions

    @IBAction func submitButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                let userId = "demo_user" // replace later with Auth user id

                let campus = campusTextField.title(for: .normal) ?? ""
                let building = buildingTextField.text ?? ""
                let classroom = classroomTextField.text ?? ""
                let desc = descriptionTextView.text ?? ""

                try validate(campus: campus, building: building, classroom: classroom, desc: desc)

                // Upload image (optional)
                var imageUrl: String? = nil
                if let img = pickedImage {
                    imageUrl = try await uploadToCloudinary(image: img)
                }

                // Save request
                try await saveToFirestore(
                    userId: userId,
                    campus: campus,
                    building: building,
                    classroom: classroom,
                    desc: desc,
                    imageUrl: imageUrl
                )

                await MainActor.run {
                    sender.isEnabled = true
                    self.view.isUserInteractionEnabled = true
                    self.clearForm()
                    self.showAlert(title: "Done", message: "Request submitted ✅")
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

    private func validate(campus: String, building: String, classroom: String, desc: String) throws {
        let campusT = campus.trimmingCharacters(in: .whitespacesAndNewlines)
        let buildingT = building.trimmingCharacters(in: .whitespacesAndNewlines)
        let classroomT = classroom.trimmingCharacters(in: .whitespacesAndNewlines)
        let descT = desc.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !campusT.isEmpty, !buildingT.isEmpty, !classroomT.isEmpty, !descT.isEmpty else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Please fill all fields before submitting."])
        }
    }

    // MARK: - Firestore

    private func saveToFirestore(
        userId: String,
        campus: String,
        building: String,
        classroom: String,
        desc: String,
        imageUrl: String?
    ) async throws {

        let payload: [String: Any] = [
            "userId": userId,
            "campus": campus.trimmingCharacters(in: .whitespacesAndNewlines),
            "building": building.trimmingCharacters(in: .whitespacesAndNewlines),
            "classroom": classroom.trimmingCharacters(in: .whitespacesAndNewlines),
            "problemDescription": desc.trimmingCharacters(in: .whitespacesAndNewlines),
            "imageUrl": imageUrl as Any,
            "status": "submitted",
            "createdAt": FieldValue.serverTimestamp()
        ]

        try await db.collection("requests").addDocument(data: payload)
    }

    // MARK: - Cloudinary

    private func uploadToCloudinary(image: UIImage) async throws -> String {
        guard cloudName != "YOUR_CLOUD_NAME", uploadPreset != "YOUR_UNSIGNED_PRESET" else {
            throw NSError(domain: "Cloudinary", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Set Cloudinary cloudName & uploadPreset first."])
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

    // MARK: - Helpers

    private func clearForm() {
        campusTextField.setTitle("Select Campus", for: .normal)
        buildingTextField.text = ""
        classroomTextField.text = ""
        descriptionTextView.text = ""
        pickedImage = nil
        previewImageView?.image = nil
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

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

private extension Data {
    mutating func append(_ string: String) {
        self.append(string.data(using: .utf8)!)
    }
}
