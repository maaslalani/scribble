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

class ViewController: UIViewController, VNDocumentCameraViewControllerDelegate, UITextViewDelegate {
    
    @IBOutlet weak var textView: UITextView!
    
    var showInMarkdown = true
    var detectedText = ""
    var textRecognitionRequest = VNRecognizeTextRequest(completionHandler: nil)
    
    private let textRecognizedWorkQueue = DispatchQueue(label: "TextDetect", qos: .userInitiated)

    @IBAction func buttonTakePhoto(_ sender: Any) {
        let scannerViewController = VNDocumentCameraViewController();
        scannerViewController.delegate = self
        present(scannerViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        self.becomeFirstResponder()
        setupVision()
    }
    
    private func setupVision() {
        textRecognitionRequest.usesLanguageCorrection = true
        textRecognitionRequest.recognitionLevel = .accurate
        
        textRecognitionRequest = VNRecognizeTextRequest { (request, error) in
            let observations = request.results as! [VNRecognizedTextObservation]
            for observation in observations {
                self.detectedText += (observation.topCandidates(1).first!.string + "\n")
            }
            
            DispatchQueue.main.async {
                self.displayText()
            }
        }
    }
    
    private func toggleMarkdown() { showInMarkdown = !showInMarkdown }
    
    private func displayText() {
        textView.attributedText = showInMarkdown
            ? MarkdownParser().parse(detectedText)
            : NSAttributedString(string: detectedText)
    }
    
    private func recognizeText(_ image: UIImage) {
        let cgImage = image.cgImage!
        textView.text = ""
        textRecognizedWorkQueue.async {
            let requestHandler = VNImageRequestHandler(cgImage : cgImage)
            try! requestHandler.perform([self.textRecognitionRequest])
        }
    }

    func textViewDidChange(_ textView: UITextView) {
        detectedText = textView.text;
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
        controller.dismiss(animated: true)
        
        if scan.pageCount > 0 {
            recognizeText(scan.imageOfPage(at: 0))
        }
    }
    
    func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
        controller.dismiss(animated: true)
    }
    
    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        controller.dismiss(animated: true)
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if (motion != .motionShake) { return }
        if (detectedText == "") { return }
        
        toggleMarkdown()
        displayText()
    }
}
