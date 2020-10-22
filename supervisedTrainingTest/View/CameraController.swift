//
//  CameraController.swift
//  supervisedTrainingTest
//
//  Created by itsupport on 19/10/2020.
//

import AVFoundation
import CoreVideo
import UIKit
import SwiftUI
import Vision

enum CameraControllerError: Swift.Error {
   case captureSessionAlreadyRunning
   case captureSessionIsMissing
   case inputsAreInvalid
   case invalidOperation
   case noCamerasAvailable
   case unknown
}

public class CameraController: NSObject {
    
    var captureSession: AVCaptureSession?
    var frontCamera: AVCaptureDevice?
    var frontCameraInput: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    func prepare(completionHandler: @escaping (Error?) -> Void){
        func createCaptureSession(){
            self.captureSession = AVCaptureSession()
        }
        
        func configureCaptureDevices() throws {
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: AVMediaType.video, position: .front)
            
            self.frontCamera = camera
            
            try camera?.lockForConfiguration()
            camera?.unlockForConfiguration()
            
        }
        
        func configureDeviceInputs() throws {
            guard let captureSession = self.captureSession else { throw CameraControllerError.captureSessionIsMissing }
            
            if let frontCamera = self.frontCamera {
                self.frontCameraInput = try AVCaptureDeviceInput(device: frontCamera)
                
                if captureSession.canAddInput(self.frontCameraInput!) { captureSession.addInput(self.frontCameraInput!)}
                else { throw CameraControllerError.inputsAreInvalid }
                
            }
            else { throw CameraControllerError.noCamerasAvailable }
            
            captureSession.startRunning()
            
        }
        
        DispatchQueue(label: "prepare").async {
            do {
                createCaptureSession()
                try configureCaptureDevices()
                try configureDeviceInputs()
            }
            
            catch {
                DispatchQueue.main.async{
                    completionHandler(error)
                }
                
                return
            }
            
            DispatchQueue.main.async {
                completionHandler(nil)
            }
        }
    }
    
    
    func displayPreview(on view: UIView) throws {
        guard let captureSession = self.captureSession, captureSession.isRunning else { throw CameraControllerError.captureSessionIsMissing }
            
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            self.previewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        self.previewLayer?.connection?.videoOrientation = .portrait
        
        view.layer.insertSublayer(self.previewLayer!, at: 0)
        self.previewLayer?.frame = view.frame
    }
}


final class CameraViewController: UIViewController {
    let cameraController = CameraController()
    var previewView: UIView!
    var resultsLabel: UILabel!
    
    var classificationController: VideoController!
    private var observer: Any!

    override func viewDidLoad() {
        
        previewView = UIView(frame: CGRect(x:0, y:0, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height))
        previewView.contentMode = UIView.ContentMode.scaleAspectFit

        setResultLabel()
        view.addSubview(previewView)
        view.addSubview(resultsLabel)
        
        classificationController = VideoController(self)
        classificationController.initCapture()
    }
    
    override func viewWillLayoutSubviews() {
      super.viewWillLayoutSubviews()
        classificationController.resizePreviewLayer()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        observer = NotificationCenter.default.addObserver(self, selector: #selector(onDidReceiveData(_:)), name: .didReceiveData, object: Classification.shared)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        classificationController.videoCapture.stop()
        NotificationCenter.default.removeObserver(observer)
    }
    
    @objc func onDidReceiveData(_ notification:Notification) {
        if let result = notification.userInfo?["request"] as? VNCoreMLRequest {
            processObservations(for: result, error: nil)
        }
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
      DispatchQueue.main.async {
        if let results = request.results as? [VNClassificationObservation] {
          if results.isEmpty {
            self.resultsLabel.text = "nothing found"
          } else {
            let top3 = results.prefix(3).map { observation in
              String(format: "%@ %.1f%%", observation.identifier, observation.confidence * 100)
            }
            self.resultsLabel.text = top3.joined(separator: "\n")
          }
        } else if let error = error {
          self.resultsLabel.text = "error: \(error.localizedDescription)"
        } else {
          self.resultsLabel.text = "???"
        }

      }
    }
}

extension CameraViewController : UIViewControllerRepresentable{
    public typealias UIViewControllerType = CameraViewController
    
    public func makeUIViewController(context: UIViewControllerRepresentableContext<CameraViewController>) -> CameraViewController {
        return CameraViewController()
    }
    
    public func updateUIViewController(_ uiViewController: CameraViewController, context: UIViewControllerRepresentableContext<CameraViewController>) {
    }
    
}


extension CameraViewController {
    func setResultLabel()  {
        resultsLabel = UILabel()
        resultsLabel.backgroundColor = .gray
        resultsLabel.layer.borderWidth = 5
        resultsLabel.layer.borderColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
        resultsLabel.layer.cornerRadius = 10
        resultsLabel.numberOfLines = 3
        resultsLabel.layer.masksToBounds = true
        resultsLabel.frame = CGRect(x: 0, y: 0, width: 200, height: 90)
        resultsLabel.text = "Result... "
        resultsLabel.center.x = self.view.center.x
        
        resultsLabel.textAlignment = .center
    }
}
