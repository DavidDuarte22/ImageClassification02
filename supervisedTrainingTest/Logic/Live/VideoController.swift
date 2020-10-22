//
//  VideoController.swift
//  supervisedTrainingTest
//
//  Created by itsupport on 22/10/2020.
//

import Foundation
import AVFoundation

final class VideoController {
    var videoCapture: VideoCapture!
    
    var parent: CameraViewController

    init(_ parent: CameraViewController) {
        self.parent = parent
    }
    
    func initCapture() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        
        videoCapture.frameInterval = 1
        
        videoCapture.setUp(sessionPreset: .high) { success in
          if success {
            // Add the video preview into the UI.
            if let previewLayer = self.videoCapture.previewLayer {
                self.parent.previewView.layer.addSublayer(previewLayer)
              self.resizePreviewLayer()
            }
            self.videoCapture.start()
          }
        }
    }

    func resizePreviewLayer() {
        videoCapture.previewLayer?.frame = parent.previewView.bounds
    }
}

extension VideoController: VideoCaptureDelegate {
  func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
    Classification.shared.classify(sampleBuffer: sampleBuffer)
  }
}
