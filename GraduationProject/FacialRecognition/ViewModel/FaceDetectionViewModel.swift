//
//  FaceDetectionViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import AVFoundation

class FaceDetectionViewModel: NSObject, ObservableObject
{
    @Published var faceBoundingBoxes: [CGRect] = []
    
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()

    func detectFaces(in pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try imageRequestHandler.perform([faceDetectionRequest])
            if let results = faceDetectionRequest.results {
                DispatchQueue.main.async {
                    self.faceBoundingBoxes = results.map { $0.boundingBox }
                }
            }
        } catch {
            print(error)
        }
    }
}
