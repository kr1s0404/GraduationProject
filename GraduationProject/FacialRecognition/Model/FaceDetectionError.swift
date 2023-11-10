//
//  FaceDetectionError.swift
//  GraduationProject
//
//  Created by Kris on 11/11/23.
//

import Foundation

enum FaceDetectionError: Error {
    case cameraInputInitializationFailed
    case videoOutputInitializationFailed
    case photoOutputInitializationFailed
    case imageProcessingFailed(String)
    case modelSetupFailed(String)
    case dataConversionFailed(String)
    case imageFetchFailed(String)
}
