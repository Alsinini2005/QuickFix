import UIKit
import FirebaseAuth
import FirebaseFirestore

final class AddNewRequestViewController: UIViewController {

    // MARK: - Outlets (optional to avoid crashes)
    @IBOutlet weak var campusButton: UIButton?
    @IBOutlet weak var buildingTextField: UITextField?
    @IBOutlet weak var classroomTextField: UITextField?
    @IBOutlet weak var descriptionTextField: UITextField?
    @IBOutlet weak var previewImageView: UIImageView?

    // MARK: - State
    private var pickedImage: UIImage?

    // MARK: - Campus options
    private let campusOptions = ["Campus A", "Campus B", "Dilmonia"]

    // MARK: - Cloudinary
    private let cloudName = "userrequest"
    private let uploadPreset = "Request"

    // MARK: - Firebase
    private let db = Firestore.firestore()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        debugOutlets()
    }

    private func debugOutlets() {
        print("DEBUG campusButton:", campusButton as Any)
        print("DEBUG buildingTextField:", buildingTextField as Any)
        print("DEBUG classroomTextField:", classroomTextField as Any)
        print("DEBUG descriptionTextField:", descriptionTextField as Any)
        print("DEBUG previewImageView:", previewImageView as Any)
    }

    private func setupUI() {
        campusButton?.setTitle("Select Campus", for: .normal)

        previewImageView?.contentMode = .scaleAspectFill
        previewImageView?.layer.cornerRadius = 12
        previewImageView?.layer.masksToBounds = true

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }

    @objc private func dismissKeyboard() { view.endEditing(true) }

    // MARK: - Campus picker
    @IBAction func campusButtonTapped(_ sender: UIButton) {
        print("✅ campusButtonTapped fired")

        let sheet = UIAlertController(title: "Select Campus", message: nil, preferredStyle: .actionSheet)

        campusOptions.forEach { campus in
            sheet.addAction(UIAlertAction(title: campus, style: .default) { _ in
                sender.setTitle(campus, for: .normal)
            })
        }

        sheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))

        if let pop = sheet.popoverPresentationController {
            pop.sourceView = sender
            pop.sourceRect = sender.bounds
        }

        present(sheet, animated: true)
    }

    // MARK: - Image Picker
    @IBAction func uploadImageTapped(_ sender: UIButton) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }

    // MARK: - Submit
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        sender.isEnabled = false
        view.isUserInteractionEnabled = false

        Task {
            do {
                guard let campusBtn = campusButton,
                      let buildingTF = buildingTextField,
                      let classroomTF = classroomTextField,
                      let descTF = descriptionTextField else {
                    debugOutlets()
                    throw NSError(domain: "Outlets", code: 0,
                                  userInfo: [NSLocalizedDescriptionKey: "Some outlets are not connected in storyboard."])
                }

                let campus = campusBtn.title(for: .normal) ?? ""
                let building = try parseInt(buildingTF.text ?? "", name: "Building")
                let classroom = try parseInt(classroomTF.text ?? "", name: "Classroom")
                let desc = descTF.text ?? ""

                try validate(campus: campus, building: building, classroom: classroom, desc: desc)

                let imageUrl = try await uploadToCloudinaryIfConfigured(image: pickedImage)

                try await saveToFirestore(
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

    // MARK: - Validation
    private func validate(campus: String, building: Int, classroom: Int, desc: String) throws {
        guard campus != "Select Campus",
              !campus.isEmpty,
              building > 0,
              classroom > 0,
              !desc.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw NSError(domain: "Validation", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Please fill all fields."])
        }
    }

    // MARK: - Firestore
    private func saveToFirestore(
        campus: String,
        building: Int,
        classroom: Int,
        desc: String,
        imageUrl: String?
    ) async throws {

        var payload: [String: Any] = [
            "title": desc,
            "campus": campus,
            "building": building,
            "classroom": classroom,
            "problemDescription": desc,
            "status": "pending",
            "createdAt": Timestamp(date: Date())
        ]

        if let imageUrl, !imageUrl.isEmpty {
            payload["imageUrl"] = imageUrl
        }

        try await db.collection("StudentRepairRequests").addDocument(data: payload)
    }

    // MARK: - Cloudinary Upload
    private func uploadToCloudinaryIfConfigured(image: UIImage?) async throws -> String? {
        guard let image else { return nil }

        guard let jpeg = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "Image", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: "Image encoding failed"])
        }

        let boundary = UUID().uuidString
        let url = URL(string: "https://api.cloudinary.com/v1_1/\(cloudName)/image/upload")!

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()

        func addField(_ name: String, _ value: String) {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }

        addField("upload_preset", uploadPreset)

        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"image.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(jpeg)
        body.append("\r\n".data(using: .utf8)!)
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        let (data, _) = try await URLSession.shared.upload(for: req, from: body)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        return json?["secure_url"] as? String
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

extension AddNewRequestViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        let img = (info[.editedImage] as? UIImage) ?? (info[.originalImage] as? UIImage)
        pickedImage = img
        previewImageView?.image = img
    }
}
