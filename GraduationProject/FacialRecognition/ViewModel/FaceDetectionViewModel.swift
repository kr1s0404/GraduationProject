//
//  FaceDetectionViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import AVFoundation

final class FaceDetectionViewModel: NSObject, ObservableObject
{
    @Published var faces: [FaceData] = []
    @Published var capturedImage: UIImage?
    
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        photoOutput = AVCapturePhotoOutput()
        
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
            
            if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            } else {
                throw NSError(domain: "FaceCameraViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize photo output."])
            }
            
            videoOutput?.connection(with: AVMediaType.video)?.videoOrientation = .portrait
            
        } catch {
            handleError(error.localizedDescription)
        }
    }
    
    func detectFaces(in pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results {
                DispatchQueue.main.async { [weak self] in
                    self?.faces = results.map { FaceData(boundingBox: $0.boundingBox, landmarks: $0.landmarks) }
                }
            }
        } catch {
            self.handleError("Error: Face landmarks detection failed - \(error.localizedDescription)")
        }
    }
    
    func captureFace() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    private func handleError(_ errorMessage: String) {
        self.errorMessage = "\(errorMessage)"
        showAlert.toggle()
    }
}


extension FaceDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFaces(in: pixelBuffer)
    }
}

extension FaceDetectionViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            handleError(error.localizedDescription)
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}
