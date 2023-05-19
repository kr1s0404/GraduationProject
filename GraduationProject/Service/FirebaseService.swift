//
//  FirebaseService.swift
//  GraduationProject
//
//  Created by Kris on 5/17/23.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore

enum Collections: String {
    case Users = "users"
}

final class FirebaseService: ObservableObject
{
    static let shared = FirebaseService()
    let database = Firestore.firestore()
    
    enum FirebaseError: Error {
        case documentNotFound
        case decodingError
    }
    
    func fetch<T: Decodable>(of type: T.Type, with query: Query) async throws -> T {
        do {
            let querySnapshot = try await query.getDocuments()
            guard let document = querySnapshot.documents.first else { throw FirebaseError.documentNotFound }
            let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: .prettyPrinted)
            let decodedData = try JSONDecoder().decode(T.self, from: jsonData)
            return decodedData
        } catch let error {
            throw error
        }
    }
}


