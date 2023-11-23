//
//  CameraUIViewController.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import UIKit
import AVFoundation

class CameraUIViewController: UIViewController, UIGestureRecognizerDelegate
{
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var captureDevice: AVCaptureDevice?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let captureSession = captureSession else { return }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.frame = view.layer.bounds
        previewLayer?.videoGravity = .resizeAspectFill
        
        if let previewLayer = previewLayer {
            view.layer.addSublayer(previewLayer)
        }
        
        let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        pinchRecognizer.delegate = self
        view.addGestureRecognizer(pinchRecognizer)
        captureDevice = AVCaptureDevice.default(for: AVMediaType.video)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession?.stopRunning()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async {
            if !(self.captureSession?.isRunning ?? false) {
                self.captureSession?.startRunning()
            }
        }
    }
    
    @objc func handlePinchGesture(_ gesture: UIPinchGestureRecognizer) {
        guard let device = captureDevice else { return }
        
        if gesture.state == .changed {
            let maxZoomFactor = device.activeFormat.videoMaxZoomFactor
            let pinchVelocityDividerFactor: CGFloat = 5.0
            
            do {
                try device.lockForConfiguration()
                defer { device.unlockForConfiguration() }
                
                var newZoomFactor = device.videoZoomFactor + atan2(gesture.velocity, pinchVelocityDividerFactor)
                newZoomFactor = max(1.0, min(newZoomFactor, maxZoomFactor))
                device.videoZoomFactor = newZoomFactor
            } catch {
                print("Error locking configuration")
            }
        }
    }
}
