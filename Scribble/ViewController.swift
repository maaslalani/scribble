//
//  ViewController.swift
//  Scribble
//
//  Created by Maas Lalani on 2019-10-12.
//  Copyright © 2019 Maas Lalani. All rights reserved.
//

import UIKit
import Vision
import VisionKit

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate {
    @IBOutlet weak var textView: UITextView!
    
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    private let textRecognizedWorkQueue = DispatchQueue(label: "VisionScannerQueue",
                                                        qos: .userInitiated,
                                                        attributes: [],
                                                        autoreleaseFrequency: .workItem)

    @IBAction func buttonTakePhoto(_ sender: Any) {
        let scannerViewController = VNDocumentCameraViewController();
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVision()
    }
    
    private func setupVision() {
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            guard let observations = request.results as? [VNRecognizedTextObservation] else { return }
            
            var detectedText = ""
            for observation in observations {
                guard let topCandidate = observation.topCandidates(1).first else { return }
                
                detectedText += (topCandidate.string + "\n")
            }
            
            DispatchQueue.main.async {
                self.textView.text = detectedText
                self.textView.flashScrollIndicators()
            }
            
            self.textRecognitionRequest.recognitionLevel = .accurate
        }
    }
    
    private func recognizeText(_ image: UIImage) {
        guard let cgImage = image.cgImage else { return }
        textView.text = ""
        textRecognizedWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try requestHandler.perform([self.textRecognitionRequest])
            } catch {
                print(error)
            }
        }
    }
    
    func compressImage(_ originalImage: UIImage) -> UIImage {
        guard let imageData = originalImage.jpegData(compressionQuality: 1),
            let reloadedImage = UIImage(data: imageData)
        else {
            return originalImage
        }
        return reloadedImage
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        let newImage = compressImage(scan.imageOfPage(at: 0))
        controller.dismiss(animated: true)
        recognizeText(newImage)
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
