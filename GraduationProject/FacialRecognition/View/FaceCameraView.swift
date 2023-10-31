//
//  FaceCameraView.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import AVFoundation

struct FaceCameraView: UIViewRepresentable
{
    @ObservedObject var viewModel: FaceDetectionViewModel

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        // Setup AVCaptureSession
        let captureSession = AVCaptureSession()
        guard let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
              let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
              captureSession.canAddInput(videoDeviceInput) else { return view }
        captureSession.addInput(videoDeviceInput)
        
        // Setup AVCaptureVideoDataOutput
        let videoDataOutput = AVCaptureVideoDataOutput()
        videoDataOutput.setSampleBufferDelegate(context.coordinator, queue: DispatchQueue(label: "VideoDataOutputQueue"))
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
        }
        
        // Setup Preview Layer
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)

        captureSession.startRunning()

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var viewModel: FaceDetectionViewModel

        init(viewModel: FaceDetectionViewModel) {
            self.viewModel = viewModel
        }

        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            viewModel.detectFaces(in: pixelBuffer)
        }
    }
}
