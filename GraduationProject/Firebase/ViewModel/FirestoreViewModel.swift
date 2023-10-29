//
//  FirebaseViewModel.swift
//  GraduationProject
//
//  Created by Kris on 5/19/23.
//

import SwiftUI

@MainActor
class FirestoreViewModel: ObservableObject
{
    private var firestoreService: FirestoreServiceProtocol
    private var imageService: ImageServiceProtocol
    
    init(firestoreService: FirestoreServiceProtocol,
         imageService: ImageServiceProtocol) {
        self.firestoreService = firestoreService
        self.imageService = imageService
    }
    
    func uploadImageAndCreateDocument(image: UIImage, in collection: Collection) async {
        guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
        
        do {
            let documentRef = try await firestoreService.createDocument(data: [String: String](),
                                                                        in: collection)
            let documentID = documentRef.documentID
            
            let imageURL = try await imageService.uploadImage(imageData: imageData,
                                                              in: "images/\(UUID().uuidString).jpg")
            
            let dataToSave = ImageData(id: documentID, imageURL: imageURL.absoluteString)
            
            try await firestoreService.updateDocument(data: dataToSave,
                                                      in: collection,
                                                      documentId: documentID)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    func fetchDocuments<T: Codable>(from collection: Collection, as type: T.Type) async -> [T] {
        do {
            return try await firestoreService.fetchDocuments(from: collection, as: type)
        } catch {
            print("Error: \(error.localizedDescription)")
            return []
        }
    }

    func updateDocument<T: Codable>(data: T, in collection: Collection, documentId: String) async {
        do {
            try await firestoreService.updateDocument(data: data, in: collection, documentId: documentId)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }

    func deleteDocument(in collection: Collection, documentId: String) async {
        do {
            try await firestoreService.deleteDocument(in: collection, documentId: documentId)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
    }
}
