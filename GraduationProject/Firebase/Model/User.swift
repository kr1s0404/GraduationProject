//
//  User.swift
//  GraduationProject
//
//  Created by Kris on 5/19/23.
//

import Foundation

struct User: Decodable {
    let firstName: String
    let lastName: String
    let birthYear: Int

    enum CodingKeys: String, CodingKey {
        case firstName = "first"
        case lastName = "last"
        case birthYear = "born"
    }
}
