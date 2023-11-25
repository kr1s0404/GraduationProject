//
//  Suspect.swift
//  GraduationProject
//
//  Created by Kris on 11/11/23.
//

import SwiftUI
import Vision

struct Suspect: Identifiable, Equatable {
    let id: String
    let suspectData: SuspectData
    var uiImage: UIImage
    var detectedImage: UIImage?
    var faceMLMultiArray: MLMultiArray?
    var score: Double?
}

struct SuspectData: Codable, Equatable
{
    let id: String
    let name: String
    let age: Int
    let sex: Bool
    let latitude: Double
    let longitude: Double
    let imageURL: String
}
