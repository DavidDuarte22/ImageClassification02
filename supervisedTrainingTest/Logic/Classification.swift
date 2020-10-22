//
//  ImageClassification.swift
//  supervisedTrainingTest
//
//  Created by itsupport on 22/10/2020.
//

import UIKit
import CoreML
import Vision

class Classification {
   let semaphore = DispatchSemaphore(value: 2)
  
   static let shared = Classification()
   
   private init() {
       
   }
   
   let visionModel: VNCoreMLModel = {
       do {
           // Create an instance of HealthySnacks. This is the class from the .mlmodel file’s automatically generated code.
           // You won’t use this class directly, only so you can pass its MLModel object to Vision.
         let multiSnacks = MultiSnacks()
         // Create a VNCoreMLModel object. This is a wrapper object that connects the MLModel instance from the Core ML framework with Vision.
         return try VNCoreMLModel(for: multiSnacks.model)
       } catch {
         fatalError("Failed to create VNCoreMLModel: \(error)")
       }
     }()
   
   lazy var classificationRequest: VNCoreMLRequest = {
       // Create the VNCoreMLRequest object. This object will perform the actual actions of converting the input image to a CVPixelBuffer, scaling it to 227×227, running the Core ML model, interpreting the results, and so on.
       // Vision will automatically scale the image to the correct size.
       let request = VNCoreMLRequest(model: visionModel, completionHandler: { [weak self] request, error in
           NotificationCenter.default.post(name: .didReceiveData, object: self, userInfo: ["request": request])
           ///TODO: Launch next event
           //self?.processObservations(for: request, error: error)
           
       })
       // The imageCropAndScaleOption tells Vision how it should resize the photo down to the 227×227 pixels that the model expects.
       request.imageCropAndScaleOption = .centerCrop
       return request
   }()
   
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
   
   func classify(sampleBuffer: CMSampleBuffer) {
     if let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
       // Tell Vision about the orientation of the image.
//        let orientation = CGImagePropertyOrientation(UIDevice.current.orientation)

       // Get additional info from the camera.
       var options: [VNImageOption : Any] = [:]
       if let cameraIntrinsicMatrix = CMGetAttachment(sampleBuffer, key: kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, attachmentModeOut: nil) {
         options[.cameraIntrinsics] = cameraIntrinsicMatrix
       }

       // The semaphore is used to block the VideoCapture queue and drop frames
       // when Core ML can't keep up.
       semaphore.wait()

       // For better throughput, perform the prediction on a background queue
       // instead of on the VideoCapture queue.
       DispatchQueue.global(qos: .userInitiated).async {
         let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: options)
         do {
           try handler.perform([self.classificationRequest])
         } catch {
           print("Failed to perform classification: \(error)")
         }
           
         self.semaphore.signal()
       }
     }
   }
}
