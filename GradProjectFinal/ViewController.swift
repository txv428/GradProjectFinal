
import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    // Declaration of variables and UI Objects.
    @IBOutlet weak var rustIMage: UIImageView!
    @IBOutlet var label: UILabel!
    let imagePicker = UIImagePickerController()
    var scale: Int = 0
    var scaleDescription: String = ""
    var randomImage = ["2.png", "3.png", "20.png", "26.png", "31.png", "34.png", "39.png", "40.png", "67.png", "68.png", "69.png", "70.png", "71.png", "72.png"].randomElement()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        imagePicker.allowsEditing = false
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        rustIMage.tintColor = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)
        rustIMage.image = UIImage(named: randomImage!)
        analyzeTestImage(UIImage(named: randomImage!)!)
    }
    
    // Analyzes image and classifies it
    func analyzeTestImage(_ testImage: UIImage) {
        rustIMage.image = testImage
        guard let ciImage = CIImage(image: testImage) else {
            fatalError("Can't create CIImage from UIImage")
        }
        
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async {
            let handler = VNImageRequestHandler(ciImage: ciImage)
            try? handler.perform([self.mlmodelClassificationRequest])
        }
    }
    
    // Requests all the mlmodels for classification
    lazy var mlmodelClassificationRequest: VNCoreMLRequest = {
        do {
            let model = try VNCoreMLModel(for: ImageClassifier().model)
            return VNCoreMLRequest(model: model, completionHandler: self.handleClassification)
        } catch {
            fatalError("Can't load Vision ML model: \(error)")
        }
    }()
    
    // Classification and confidence results from VNClassificationObservation
    func handleClassification(request: VNRequest, error: Error?) {
        guard let observations = request.results as? [VNClassificationObservation]
            else { fatalError("Unexpected result type from VNCoreMLRequest") }
        
        guard let best = observations.first
            else { fatalError("Can't get best result") }
        
        if best.confidence < 0.2 && best.confidence > 0.0 {
            scale = 1
            scaleDescription = "slightly rusted"
        }
        else if best.confidence < 0.4 && best.confidence > 0.2 {
            scale = 2
            scaleDescription = "slightly rusted"
        }
        else if best.confidence < 0.6 && best.confidence > 0.4 {
            scale = 3
            scaleDescription = "partly rusted"
        }
        else if best.confidence < 0.8 && best.confidence > 0.6 {
            scale = 4
            scaleDescription = "mostly rusted"
        }
        else if best.confidence < 1.0 && best.confidence > 0.8 {
            scale = 5
            scaleDescription = "mostly rusted"
        }
        
        DispatchQueue.main.async {
            self.label.text = "Classification: \"\(best.identifier)\"\nScale: \"\(self.scale) - \(self.scaleDescription)\"\nConfidence: \(best.confidence)"
        }
    }
    
    // MARK - IBActions
    // Selects image from photo library
    @IBAction func tappedButton(_ sender: Any) {
        imagePicker.sourceType = .photoLibrary
        present(imagePicker, animated: true, completion: nil)
    }
    
    // Selects image taken through camera
    @IBAction func takePhoto(_ sender: Any) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            imagePicker.sourceType = .camera
            present(imagePicker, animated: true, completion: nil)
        } else {
            showCameraNotAvailableAlert()
        }
    }
    
    // If camera is not available or testing in simulator
    private func showCameraNotAvailableAlert() {
        let alertController = UIAlertController.init(title: "Camera Not Available", message: nil, preferredStyle: .alert)
        alertController.addAction(UIAlertAction.init(title: "OK", style: .default, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK - UIImagePickerControllerDelegate
    // chooses image selected and analyzes it.
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let pickedImage = info[.originalImage] as? UIImage {
            rustIMage.image = pickedImage
            analyzeTestImage(pickedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
}

