import UIKit

struct Ticket {
    var ticketID: String
    var createdAt: String
    var campus: String
    var buildingNumber: String
    var classNumber: String
    var problemDescription: String
    var imageName: String
    var status: String
    var title: String
}

class FeedbackTableViewController: UITableViewController {
    
    @IBOutlet weak var lblTicketID: UILabel!
    @IBOutlet weak var lblTicketName: UILabel!
    @IBOutlet weak var lblLocation: UILabel!
    @IBOutlet weak var lblIssue: UILabel!
    @IBOutlet weak var lblStatus: UILabel!
    @IBOutlet weak var lblCreated: UILabel!
    @IBOutlet weak var txtComment: UITextField!
    @IBOutlet weak var btnSubmit: UIButton!
    
    
    @IBOutlet weak var btnRate1: UIButton!
    @IBOutlet weak var btnRate2: UIButton!
    @IBOutlet weak var btnRate3: UIButton!
    @IBOutlet weak var btnRate4: UIButton!
    @IBOutlet weak var btnRate5: UIButton!
    
    private var rate: Int = 0
    private var ratingButtons: [UIButton]!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        lblTicketID.text = "#001"
        lblTicketName.text = "Network"
        lblLocation.text = "Building 12"
        lblStatus.text = "assigned"
        lblIssue.text = "Wifi router was damaged"
        lblCreated.text = "12-12-2025"
        
        ratingButtons = [btnRate1, btnRate2, btnRate3, btnRate4, btnRate5]
        updateRatingButtons()
    }
    
    private func updateRatingButtons() {
        for (index, button) in ratingButtons.enumerated() {
            let imageName = (index < rate) ? "star.fill" : "star"
            button.setImage(UIImage(systemName: imageName), for: .normal)
        }
    }
    
    @IBAction func btnRate1(_ sender: Any) {
        rate = 1
        updateRatingButtons()
    }
    
    @IBAction func btnRate2(_ sender: Any) {
        rate = 2
        updateRatingButtons()
    }
    
    @IBAction func btnRate3(_ sender: Any) {
        rate = 3
        updateRatingButtons()
    }
    
    @IBAction func btnRate4(_ sender: Any) {
        rate = 4
        updateRatingButtons()
    }
    
    @IBAction func btnRate5(_ sender: Any) {
        rate = 5
        updateRatingButtons()
    }
    
    @IBAction func btnSubmit(_ sender: Any) {
        guard let comment = txtComment.text, !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            showAlert(message: "Please enter a comment before submitting.")
            return
        }
        
        if rate == 0 {
            showAlert(message: "Please select a rating before submitting.")
            return
        }
        
        // Proceed with submission logic here
        // For example: submit the comment and rate to a server or database
        print("Submitted - Rate: \(rate), Comment: \(comment)")
        
        // Optionally, clear the fields or navigate away after submission
        txtComment.text = ""
        rate = 0
        updateRatingButtons()
        
        showAlert(message: "Feedback submitted successfully!")
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Validation Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}



class RequestDetailsTableViewController: UITableViewController {
    
    @IBOutlet weak var lblTicketID: UILabel!
    @IBOutlet weak var lblCreatedAt: UILabel!
    
    @IBOutlet weak var lblCampus: UILabel!
    @IBOutlet weak var lblBuildingNumber: UILabel!
    @IBOutlet weak var lblClassNumber: UILabel!
    
    @IBOutlet weak var lblProblemDescription: UILabel!
    
    @IBOutlet weak var imgSubmittedImage: UIImageView!
    
    @IBOutlet weak var btnEdit: UIButton!
    @IBOutlet weak var btnFeedback: UIButton!
    
    var ticket: Ticket = Ticket(ticketID: "#001",
                                createdAt: "31 December 2025 at 13:45:50 UTC+3",
                                campus: "A",
                                buildingNumber: "3",
                                classNumber: "312",
                                problemDescription: "Wifi is disconnected while Cables are working.",
                                imageName: "IMG_0104",
                                status: "assinged",
                                title: "Fix printer issue")
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    private func updateUI() {
        lblTicketID.text = ticket.ticketID
        lblCreatedAt.text = ticket.createdAt
        lblCampus.text = ticket.campus
        lblBuildingNumber.text = ticket.buildingNumber
        lblClassNumber.text = ticket.classNumber
        lblProblemDescription.text = ticket.problemDescription
        // Assuming image is in assets or load from device, here using named for demo
        if let image = UIImage(named: ticket.imageName) {
            imgSubmittedImage.image = image
        } else {
            imgSubmittedImage.image = UIImage(systemName: "photo")
        }
        
        if ticket.status == "completed" {
            btnFeedback.isHidden = false
            btnEdit.isHidden = true
        } else {
            btnFeedback.isHidden = true
            btnEdit.isHidden = false
        }
    }
    
    @IBAction func btnEdit(_ sender: Any) {
        performSegue(withIdentifier: "editRepairSegue", sender: self)
    }
    
    @IBAction func btnFeedback(_ sender: Any) {
        // Assuming segue to Feedback screen
        performSegue(withIdentifier: "feedbackSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "editRepairSegue" {
            if let repairVC = segue.destination as? RepairTableViewController {
                repairVC.ticket = ticket
                repairVC.delegate = self
            }
        }
        // Handle feedback segue if needed
    }
}

extension RequestDetailsTableViewController: RepairDelegate {
    func didUpdateTicket(_ updatedTicket: Ticket) {
        self.ticket = updatedTicket
        updateUI()
    }
}

protocol RepairDelegate: AnyObject {
    func didUpdateTicket(_ updatedTicket: Ticket)
}



class RepairTableViewController: UITableViewController {
    
    @IBOutlet weak var TicketID: UILabel!
    
    @IBOutlet weak var CreatedAt: UILabel!
    @IBOutlet weak var txtProblemDescription: UITextField!
    
    @IBOutlet weak var txtCampus: UITextField!
    @IBOutlet weak var txtBuildingNumber: UITextField!
    @IBOutlet weak var txtClassNumber: UITextField!
    @IBOutlet weak var imgProblem: UIImageView!
    
    var ticket: Ticket!
    weak var delegate: RepairDelegate?
    
    private var originalTicket: Ticket!
    private var selectedImage: UIImage?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        originalTicket = ticket
        updateUI()
    }
    
    private func updateUI() {
        TicketID.text = ticket.ticketID
        CreatedAt.text = ticket.createdAt
        txtProblemDescription.text = ticket.problemDescription
        txtCampus.text = ticket.campus
        txtBuildingNumber.text = ticket.buildingNumber
        txtClassNumber.text = ticket.classNumber
        if let image = UIImage(named: ticket.imageName) {
            imgProblem.image = image
        } else {
            imgProblem.image = UIImage(systemName: "photo")
        }
    }
    
    private func hasChanges() -> Bool {
        return txtProblemDescription.text != originalTicket.problemDescription ||
               txtCampus.text != originalTicket.campus ||
               txtBuildingNumber.text != originalTicket.buildingNumber ||
               txtClassNumber.text != originalTicket.classNumber ||
               selectedImage != nil
    }
    
    @IBAction func btnEditImage(_ sender: Any) {
        let alert = UIAlertController(title: "Select Image", message: nil, preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { _ in
            self.openCamera()
        }))
        alert.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { _ in
            self.openPhotoLibrary()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    private func openCamera() {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    private func openPhotoLibrary() {
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        }
    }
    
    @IBAction func btnCancel(_ sender: Any) {
        if hasChanges() {
            let alert = UIAlertController(title: "Discard Changes?", message: "Are you sure you want to discard your changes?", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { _ in
                self.dismiss(animated: true, completion: nil)
            }))
            alert.addAction(UIAlertAction(title: "No", style: .cancel, handler: nil))
            present(alert, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func btnSave(_ sender: Any) {
        ticket.problemDescription = txtProblemDescription.text ?? ""
        ticket.campus = txtCampus.text ?? ""
        ticket.buildingNumber = txtBuildingNumber.text ?? ""
        ticket.classNumber = txtClassNumber.text ?? ""
        if let newImage = selectedImage {
            // For demo, save image or update name; here assuming update imageName to a new name
            ticket.imageName = "new_image_\(Date().timeIntervalSince1970)"
            // In real app, save image to documents or assets
        }
        delegate?.didUpdateTicket(ticket)
        
        let alert = UIAlertController(title: "Success", message: "Editing done successfully", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.dismiss(animated: true, completion: nil)
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension RepairTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[.originalImage] as? UIImage {
            selectedImage = image
            imgProblem.image = image
        }
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
}
