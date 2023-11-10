//
//  FaceDetectionError.swift
//  GraduationProject
//
//  Created by Kris on 11/11/23.
//

import Foundation

enum FaceDetectionError: Error {
    case cameraInputInitializationFailed(String)
    case videoOutputInitializationFailed(String)
    case photoOutputInitializationFailed(String)
    case imageProcessingFailed(String)
    case modelSetupFailed(String)
    case modelPredictionFailed
    case imageFetchFailed(String)
    case faceDetectionFailed(String)
}
