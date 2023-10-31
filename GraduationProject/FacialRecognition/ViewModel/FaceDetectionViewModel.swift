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
        
        guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
              captureSession?.canAddInput(videoInput) == true else {
            return
        }
        
        captureSession?.addInput(videoInput)
        
        if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
            // Set the video output's pixel format to 32BGRA
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            videoOutput.alwaysDiscardsLateVideoFrames = true
            captureSession?.addOutput(videoOutput)
        }
        
        videoOutput?.connection(with: AVMediaType.video)?.videoOrientation = .portrait
    }
    
    func startSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.startRunning()
        }
    }
    
    func endSession() {
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
        }
    }
    
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
            print("Error: Face detection failed - \(error.localizedDescription)")
        }
    }
}

extension FaceCameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        detectFaces(in: pixelBuffer)
    }
}

