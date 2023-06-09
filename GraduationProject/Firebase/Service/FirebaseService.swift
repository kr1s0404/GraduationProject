//
//  FirebaseService.swift
//  GraduationProject
//
//  Created by Kris on 5/17/23.
//

import SwiftUI
import FirebaseCore
import FirebaseFirestore
import FirebaseStorage

enum Collections: String {
    case Users = "users"
    case Images = "images"
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
    let storageRef = Storage.storage().reference()
    
    enum FirebaseError: Error {
        case documentNotFound
        case decodingError
        case decodingImageError
        case imageNotFound
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
    
    func uploadImage(image: UIImage) async throws -> String {
        let imagesRef = storageRef.child("images")
        let fileName = "\(UUID().uuidString).jpg"
        let spaceRef = imagesRef.child(fileName)
        
        guard let data = image.jpegData(compressionQuality: 0.5) else { throw FirebaseError.decodingImageError }
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpg"
        
        do {
            let _ = try await spaceRef.putDataAsync(data, metadata: metadata)
            let downloadURL = try await spaceRef.downloadURL()
            return downloadURL.absoluteString
        } catch let error {
            throw error
        }
    }
    
    func fetchImages() async throws -> StorageListResult {
        let imagesRef = storageRef.child("images")
        
        do {
            return try await imagesRef.listAll()
        } catch let error {
            throw error
        }
    }
}

