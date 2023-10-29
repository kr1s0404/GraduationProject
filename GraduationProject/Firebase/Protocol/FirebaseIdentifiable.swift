//
//  FirebaseIdentifiable.swift
//  GraduationProject
//
//  Created by Kris on 10/29/23.
//

import Foundation

protocol FirebaseIdentifiable: Hashable, Codable {
    var id: String { get set }
    var dictionary: [String:Any] { get }
}

extension FirebaseIdentifiable {
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}
