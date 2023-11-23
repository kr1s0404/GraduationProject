//
//  Suspect.swift
//  GraduationProject
//
//  Created by Kris on 11/11/23.
//

import SwiftUI

struct Suspect: Identifiable, Equatable {
    let id: String
    let suspectData: SuspectData
    let uiImage: UIImage
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
