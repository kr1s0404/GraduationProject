//
//  FaceDetectionViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import AVFoundation

final class FaceCameraViewModel: NSObject, ObservableObject
{
    @Published var faceBoundingBoxes: [CGRect] = []
    
    @Published var showAlert: Bool = false
    @Published var errorMessage: String?
    
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        
        do {
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  captureSession?.canAddInput(videoInput) == true else {
                throw NSError(domain: "FaceCameraViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize camera input."])
            }
            
            captureSession?.addInput(videoInput)
            
            if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                videoOutput.alwaysDiscardsLateVideoFrames = true
                captureSession?.addOutput(videoOutput)
            } else {
                throw NSError(domain: "FaceCameraViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize video output."])
            }
            
            videoOutput?.connection(with: AVMediaType.video)?.videoOrientation = .portrait
            
        } catch {
            handleError(error.localizedDescription)
        }
    }
    
    // Other methods remain the same
    
    func detectFaces(in pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
            if let results = faceDetectionRequest.results {
                DispatchQueue.main.async { [weak self] in
                    self?.faceBoundingBoxes = results.map { $0.boundingBox }
                }
            }
        } catch {
            self.handleError("Error: Face detection failed - \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ errorMessage: String) {
        self.errorMessage = "\(errorMessage)"
        showAlert.toggle()
    }
}


extension FaceCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFaces(in: pixelBuffer)
    }
}

