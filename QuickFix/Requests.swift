//
//  AddNewRequestViewController.swift
//  QuickFix
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AddNewRequestViewController: UIViewController {

    // MARK: - Outlets (connect in storyboard)
    @IBOutlet weak var campusTextField: UIButton!          // Button title shows selected campus
    @IBOutlet weak var buildingTextField: UITextField!
    @IBOutlet weak var classroomTextField: UITextField!
    @IBOutlet weak var descriptionTextField: UITextField! // ✅ BACK TO UITextField
    @IBOutlet weak var previewImageView: UIImageView?     // optional

    // MARK: - State
    private var pickedImage: UIImage?

    // MARK: - Campus options
    private let campusOptions = ["Campus A", "Campus B", "Dilmonia"]

    // MARK: - Cloudinary (OPTIONAL)
    private let cloudName = "YOUR_CLOUD_NAME"
    private let uploadPreset = "YOUR_UNSIGNED_PRESET"

    // MARK: - Firebase
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        assertOutletsConnected()
        setupUI()
    }

    private func assertOutletsConnected() {
        precondition(campusTextField != nil, "❌ campusTextField not connected")
        precondition(buildingTextField != nil, "❌ buildingTextField not connected")
        precondition(classroomTextField != nil, "❌ classroomTextField not connected")
        precondition(descriptionTextField != nil, "❌ descriptionTextField not connected")
        // previewImageView is optional
    }

    // MARK: - UI
    private func setupUI() {

        let title = (campusTextField.title(for: .normal) ?? "").trimmingCharacters(in: .whitespaces)
        if title.isEmpty {
            campusTextField.setTitle("Select Campus", for: .normal)
        }

        previewImageView?.contentMode = .scaleAspectFill
        previewImageView?.layer.cornerRadius = 12
        previewImageView?.layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() {
        view.endEditing(true)
    }

    // MARK: - Campus picker
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
                guard let uid = Auth.auth().currentUser?.uid else {
                    await resetUI(sender, message: "Please login first.")
                    return
                }

                let campus = campusTextField.title(for: .normal) ?? ""
                let buildingText = buildingTextField.text ?? ""
                let classroomText = classroomTextField.text ?? ""
                let desc = descriptionTextField.text ?? ""

                let building = try parseInt(buildingText, name: "Building")
                let classroom = try parseInt(classroomText, name: "Classroom")

                try validate(campus: campus, building: building, classroom: classroom, desc: desc)

                let imageUrl = try await uploadToCloudinaryIfConfigured(image: pickedImage)

                try await saveToFirestore(
                    userId: uid,
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
                await resetUI(sender, message: error.localizedDescription)
            }
        }
    }

    private func resetUI(_ sender: UIButton, message: String) async {
        await MainActor.run {
            sender.isEnabled = true
            self.view.isUserInteractionEnabled = true
            self.showAlert(title: "Error", message: message)
        }
    }

    // MARK: - Validation
    private func validate(campus: String, building: Int, classroom: Int, desc: String) throws {
        guard campus != "Select Campus",
              !campus.isEmpty,
              building > 0,
              classroom > 0,
              !desc.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw NSError(
                domain: "Validation",
                code: 0,
                userInfo: [NSLocalizedDescriptionKey: "Please fill all fields."]
            )
        }
    }

    // MARK: - Firestore
    private func saveToFirestore(
        userId: String,
        campus: String,
        building: Int,
        classroom: Int,
        desc: String,
        imageUrl: String?
    ) async throws {

        let payload: [String: Any] = [
            "userId": userId,
            "title": desc,
            "campus": campus,
            "building": building,
            "classroom": classroom,
            "problemDescription": desc,
            "imageUrl": imageUrl as Any,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        try await db.collection("StudentRepairRequests").addDocument(data: payload)
    }

    // MARK: - Cloudinary (optional)
    private func uploadToCloudinaryIfConfigured(image: UIImage?) async throws -> String? {
        guard let image else { return nil }
        if cloudName == "YOUR_CLOUD_NAME" || uploadPreset == "YOUR_UNSIGNED_PRESET" { return nil }
        return nil // keep disabled safely
    }

    // MARK: - Image Picker
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        presentImagePicker()
    }

    private func presentImagePicker() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - Helpers
    private func parseInt(_ text: String, name: String) throws -> Int {
        guard let n = Int(text), n > 0 else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "\(name) must be a number"])
        }
        return n
    }

    private func showAlert(title: String, message: String) {
        let a = UIAlertController(title: title, message: message, preferredStyle: .alert)
        a.addAction(UIAlertAction(title: "OK", style: .default))
        present(a, animated: true)
    }
}

// MARK: - Image Picker Delegate
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
