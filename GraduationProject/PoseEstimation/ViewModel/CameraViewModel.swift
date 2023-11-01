//
//  CameraViewModel.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import SwiftUI
import CoreML
import CoreVideo
import CoreGraphics
import AVFoundation

class CameraViewModel: NSObject, ObservableObject
{
    // Pose Estimation
    @Published var joints: [CGPoint] = []

    // Pose Matching
    @Published var savedPoses: [[CGPoint]] = []
    @Published var matchConfidences: [Double] = []
    private let maxSavedPoses = 5
    
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    
    override init() {
        super.init()
        setupSession()
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video),
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
    
    func captureCurrentPose() {
        if savedPoses.count < maxSavedPoses {
            savedPoses.append(joints)
        }
    }
    
    func resetSavedPoses() {
        savedPoses.removeAll()
    }
    
    func calculatePoseMatching() {
        DispatchQueue.main.async {
            self.matchConfidences = self.savedPoses.map { savedPose in
                return self.comparePoses(currentPose: self.joints, savedPose: savedPose)
            }
        }
    }
    
    private func comparePoses(currentPose: [CGPoint], savedPose: [CGPoint]) -> Double {
        guard currentPose.count == savedPose.count, currentPose.count > 1 else { return 0.0 }

        var totalDistanceScore = 0.0
        var totalAngleScore = 0.0
        var maxObservedDistance = 0.0

        let currentAngles = calculateAngles(for: currentPose)
        let savedAngles = calculateAngles(for: savedPose)

        for i in 0 ..< currentPose.count {
            let distance = CGPoint.distance(currentPose[i], savedPose[i])
            maxObservedDistance = max(distance, maxObservedDistance)
            totalDistanceScore += distance
            
            if i < currentAngles.count && i < savedAngles.count {
                let angleDifference = abs(currentAngles[i] - savedAngles[i]) / CGFloat.pi
                totalAngleScore += Double(angleDifference)
            }
        }

        // Normalize distances and angles
        let normalizedDistances = 1.0 - totalDistanceScore / (Double(currentPose.count) * maxObservedDistance)
        let normalizedAngles = 1.0 - totalAngleScore / Double(currentAngles.count)

        // Weighting for angles vs. distances (0.5 implies equal weight to both)
        let distanceWeight = 0.5
        let angleWeight = 1.0 - distanceWeight

        return distanceWeight * normalizedDistances + angleWeight * normalizedAngles
    }

    private func calculateAngles(for pose: [CGPoint]) -> [CGFloat] {
        guard pose.count > 2 else { return [] }
        
        var angles: [CGFloat] = []
        
        for i in 1 ..< pose.count - 1 {
            let prev = pose[i-1]
            let center = pose[i]
            let next = pose[i+1]
            let angle = center.angle(with: prev, and: next)
            angles.append(angle)
        }
        
        return angles
    }
}

extension CameraViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Process video frame here for CoreML model
        processFrame(sampleBuffer: sampleBuffer)
        
        // Calculate matching confidences for saved poses
        calculatePoseMatching()
    }
    
    func processFrame(sampleBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Pass the pixelBuffer to your CoreML model for pose estimation
        performPoseEstimation(pixelBuffer: pixelBuffer)
    }
}

extension CameraViewModel {
    func resize(pixelBuffer: CVPixelBuffer, width: Int, height: Int) -> CVPixelBuffer? {
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(width) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(height) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.transformed(by: transform)
        let ciContext = CIContext()
        
        var newPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(nil, width, height, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &newPixelBuffer)
        guard status == kCVReturnSuccess else {
            return nil
        }
        
        ciContext.render(ciImage, to: newPixelBuffer!)
        
        return newPixelBuffer
    }
    
    func performPoseEstimation(pixelBuffer: CVPixelBuffer) {
        do {
            guard let resizedBuffer = resize(pixelBuffer: pixelBuffer, width: 192, height: 192) else {
                print("Error resizing pixel buffer")
                return
            }
            
            let model = try PoseEstimationModel(configuration: .init())
            let prediction = try model.prediction(image__0: resizedBuffer)
            
            guard let multiArray = try? MLMultiArray(shape: [14, 96, 96], dataType: .double) else {
                print("Error creating multi array")
                return
            }
            
            // Directly use dataPointer without optional binding
            let output = prediction.Convolutional_Pose_Machine__stage_5_out__0
            let data = output.dataPointer.bindMemory(to: Double.self, capacity: 14 * 96 * 96)
            for i in 0 ..< 14 * 96 * 96 {
                multiArray[i] = NSNumber(value: data[i])
            }
            
            // Extract joints from multiArray
            let joints = extractJoints(from: multiArray)
            
            // Publish joints to overlay on camera view
            DispatchQueue.main.async {
                self.joints = joints
            }
            
        } catch {
            print("Error with pose estimation:", error)
        }
    }
}

extension CameraViewModel {
    func extractJoints(from multiArray: MLMultiArray) -> [CGPoint] {
        var joints = [CGPoint]()
        
        // Assuming each of the 14 channels corresponds to a joint
        for i in 0 ..< 14 {
            var maxVal: Double = -Double.infinity
            var maxLoc: CGPoint = .zero
            
            for y in 0 ..< 96 {
                for x in 0 ..< 96 {
                    let index = i * 96 * 96 + y * 96 + x
                    let value = multiArray[index].doubleValue
                    if value > maxVal {
                        maxVal = value
                        maxLoc = CGPoint(x: x, y: y)
                    }
                }
            }
            
            // Scaling factor to map 96x96 output to your view's size
            let scaleX = UIScreen.main.bounds.width / 96.0
            let scaleY = UIScreen.main.bounds.height / 96.0
            
            joints.append(CGPoint(x: maxLoc.x * scaleX, y: maxLoc.y * scaleY))
        }
        
        return joints
    }
}

