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

protocol FirebaseIdentifiable: Hashable, Codable {
    var id: String { get set }
    var dictionary: [String:Any] { get }
}

extension FirebaseIdentifiable {
    var dictionary: [String: Any] {
        return (try? JSONSerialization.jsonObject(with: JSONEncoder().encode(self))) as? [String: Any] ?? [:]
    }
}

final class FirebaseService: ObservableObject
{
    static let shared = FirebaseService()
    let database = Firestore.firestore()
    
    enum FirebaseError: Error {
        case documentNotFound
        case decodingError
    }
    
    func create<T: FirebaseIdentifiable>(_ value: T, to collection: String) async throws -> T {
        let ref = database.collection(collection).document()
        var valueToWrite: T = value
        valueToWrite.id = ref.documentID
        
        do {
            try await ref.setData(valueToWrite.dictionary)
            return valueToWrite
        } catch let error {
            throw error
        }
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
    
    func fetchAll<T: Decodable>(of type: T.Type, with query: Query) async throws -> [T] {
        do {
            var response: [T] = []
            let querySnapshot = try await query.getDocuments()
            
            for document in querySnapshot.documents {
                do {
                    let jsonData = try JSONSerialization.data(withJSONObject: document.data(), options: .prettyPrinted)
                    let decodedData = try JSONDecoder().decode(T.self, from: jsonData)
                    response.append(decodedData)
                } catch {
                    throw FirebaseError.decodingError
                }
            }
            
            return response
        } catch let error {
            throw error
        }
    }
    
    func update<T: FirebaseIdentifiable>(_ value: T, to collection: String) async throws -> T {
        let ref = database.collection(collection).document(value.id)
        
        do {
            try await ref.setData(value.dictionary)
            return value
        } catch let error {
            throw error
        }
    }
    
    func delete<T: FirebaseIdentifiable>(_ value: T, to collection: String) async throws {
        let ref = database.collection(collection).document(value.id)
        
        do {
            try await ref.delete()
        } catch let error {
            throw error
        }
    }
    
}

