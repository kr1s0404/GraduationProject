//
//  FirebaseIdentifiable.swift
//  GraduationProject
//
//  Created by Kris on 10/29/23.
//

import Foundation
import Firebase

protocol FirestoreServiceProtocol {
    func createDocument<T: Codable>(data: T, in collection: Collection) async throws -> DocumentReference
    func fetchDocuments<T: Codable>(from collection: Collection, as type: T.Type) async throws -> [T]
    func updateDocument<T: Codable>(data: T, in collection: Collection, documentId: String) async throws
    func deleteDocument(in collection: Collection, documentId: String) async throws
}
