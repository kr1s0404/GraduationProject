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

enum Collection: String {
    case Images = "images"
    case Videos = "videos"
    case Suspect = "suspects"
}

final class FirestoreService: FirestoreServiceProtocol {
    private let db = Firestore.firestore()
    
    func createDocument<T: Codable>(data: T, in collection: Collection) async throws -> DocumentReference {
        let dataAsDict = try JSONEncoder().encode(data).toDictionary()
        let newDocumentRef = db.collection(collection.rawValue).document()
        try await newDocumentRef.setData(dataAsDict)
        return newDocumentRef
    }
    
    func fetchDocuments<T: Codable>(from collection: Collection, as type: T.Type) async throws -> [T] {
        let snapshot = try await db.collection(collection.rawValue).getDocuments()
        let decoder = JSONDecoder()
        return snapshot.documents.compactMap { document in
            guard let data = try? JSONSerialization.data(withJSONObject: document.data(), options: []) else { return nil }
            return try? decoder.decode(T.self, from: data)
        }
    }
    
    func updateDocument<T: Codable>(data: T, in collection: Collection, documentId: String) async throws {
        let dataAsDict = try JSONEncoder().encode(data).toDictionary()
        try await db.collection(collection.rawValue).document(documentId).setData(dataAsDict)
    }
    
    func deleteDocument(in collection: Collection, documentId: String) async throws {
        try await db.collection(collection.rawValue).document(documentId).delete()
    }
}

extension Data {
    func toDictionary() -> [String: Any] {
        (try? JSONSerialization.jsonObject(with: self, options: .allowFragments)).flatMap { $0 as? [String: Any] } ?? [:]
    }
}
