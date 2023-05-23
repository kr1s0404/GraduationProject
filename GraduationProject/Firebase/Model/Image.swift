//
//  Image.swift
//  GraduationProject
//
//  Created by Kris on 5/23/23.
//

import Foundation

struct SuperResolutionImage: FirebaseIdentifiable, Decodable
{
    var id: String
    let imageURL: String

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case imageURL = "imageURL"
    }
}
