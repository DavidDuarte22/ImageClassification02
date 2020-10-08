//
//  ImagePicker.swift
//  supervisedTrainingTest
//
//  Created by David Duarte on 07/10/2020.
//

import UIKit
import SwiftUI
import CoreML
import Vision

struct ImagePicker: UIViewControllerRepresentable {

    @Binding var result: String
    @Binding var selectedImage: UIImage
    @Environment(\.presentationMode)  var presentationMode
    
    var sourceType: UIImagePickerController.SourceType = .photoLibrary
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIViewController(context: UIViewControllerRepresentableContext<ImagePicker>) -> UIImagePickerController {

        let imagePicker = UIImagePickerController()
        imagePicker.delegate = context.coordinator
        imagePicker.allowsEditing = false
        imagePicker.sourceType = sourceType

        return imagePicker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: UIViewControllerRepresentableContext<ImagePicker>) {

    }
}

final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
 
    var parent: ImagePicker

    init(_ parent: ImagePicker) {
        self.parent = parent
    }
 
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
 
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            parent.selectedImage = image
            
            classify(image: image)

        }
 
        parent.presentationMode.wrappedValue.dismiss()
    }
    
    //MARK: The classification part
    func classify(image: UIImage) {
        // Converts the UIImage to a CIImage object.
        guard let ciImage = CIImage(image: image) else {
            print("Unable to create CIImage")
            return
        }
        // it is best to perform the request on a background queue, so as not to block the main thread. all the calculations may take a one or two moments
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a new VNImageRequestHandler for this image
            let handler = VNImageRequestHandler(ciImage: ciImage)
            do {
                // you can perform multiple Vision requests on the same image if you want to. Here, you just use the VNCoreMLRequest object from the classificationRequest property you made earlier.
                try handler.perform([self.classificationRequest])
            } catch {
                print("Failed to perform classification: \(error)")
            }
        }
    }
    
    lazy var classificationRequest: VNCoreMLRequest = {
      do {
        // Create an instance of HealthySnacks. This is the class from the .mlmodel file’s automatically generated code.
        // You won’t use this class directly, only so you can pass its MLModel object to Vision.
        let multiSnacks = MultiSnacks()
        // Create a VNCoreMLModel object. This is a wrapper object that connects the MLModel instance from the Core ML framework with Vision.
        let visionModel = try VNCoreMLModel(for: multiSnacks.model)
        // Create the VNCoreMLRequest object. This object will perform the actual actions of converting the input image to a CVPixelBuffer, scaling it to 227×227, running the Core ML model, interpreting the results, and so on.
        // Vision will automatically scale the image to the correct size.
        let request = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] request, error in
          self?.processObservations(for: request, error: error)
        })
        // The imageCropAndScaleOption tells Vision how it should resize the photo down to the 227×227 pixels that the model expects.
        request.imageCropAndScaleOption = .centerCrop
        return request
      } catch {
        fatalError("Failed to create VNCoreMLModel: \(error)")
      }
    }()
    
    func processObservations(for request: VNRequest, error: Error?) {
        // The request’s completion handler is called on the same background queue from which you launched the request.
        DispatchQueue.main.async {
            // If everything went well, the request’s results array contains one or more VNClassificationObservation objects
            if let results = request.results as? [VNClassificationObservation] {
                // Assuming the array is not empty, it contains a VNClassificationObservation object for each possible class
                if results.isEmpty {
                    self.parent.result = "nothing found"
                } else if results[0].confidence < 0.6 {
                    self.parent.result = "not sure"
                } else {
                    let firstItems = results.prefix(3).map { result in
                        String(format: "%@ %.1f%%", result.identifier, result.confidence * 100)
                    }
                    self.parent.result = firstItems.joined(separator: "\n")
                }
            } else if let error = error {
                self.parent.result = "error: \(error.localizedDescription)"
            } else {
                self.parent.result = "???"
            }
        }
    }
}
