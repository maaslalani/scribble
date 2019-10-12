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
import MarkdownKit

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
                print(topCandidate)
                detectedText += (topCandidate.string + "\n\n")
            }
            
            DispatchQueue.main.async {
                self.textView.attributedText = MarkdownParser().parse(detectedText)
                self.textView.flashScrollIndicators()
            }
            
            self.textRecognitionRequest.usesLanguageCorrection = true
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
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        guard scan.pageCount >= 1 else {
            controller.dismiss(animated: true)
            return
        }
        
        controller.dismiss(animated: true)
        recognizeText(scan.imageOfPage(at: 0))
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        print(error)
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
}
