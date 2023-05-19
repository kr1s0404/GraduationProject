//
//  User.swift
//  GraduationProject
//
//  Created by Kris on 5/19/23.
//

import Foundation

struct User: FirebaseIdentifiable, Decodable
{
    var id: String
    let firstName: String
    let lastName: String
    let birthYear: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case firstName = "firstName"
        case lastName = "lastName"
        case birthYear = "birthYear"
    }
}
