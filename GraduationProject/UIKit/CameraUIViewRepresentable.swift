//
//  CameraUIViewRepresentable.swift
//  GraduationProject
//
//  Created by Kris on 11/21/23.
//

import SwiftUI
import AVFoundation

struct CameraUIViewRepresentable: UIViewControllerRepresentable
{
    var captureSession: AVCaptureSession?
    
    func makeUIViewController(context: Context) -> CameraUIViewController {
        let viewController = CameraUIViewController()
        viewController.captureSession = captureSession
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: CameraUIViewController, context: Context) {
        
    }
}
