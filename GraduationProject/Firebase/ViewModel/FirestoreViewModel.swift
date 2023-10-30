//
//  FirebaseViewModel.swift
//  GraduationProject
//
//  Created by Kris on 5/19/23.
//

import SwiftUI

@MainActor
final class FirestoreViewModel: ObservableObject
{
    private let firestoreService = FirestoreService()
    private let imageService = MediaService()
    
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    func uploadMediaAndCreateDocument(media: Media, in collection: Collection) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let documentRef = try await firestoreService.createDocument(data: [String: String](), in: collection)
            let documentID = documentRef.documentID
            
            switch media {
                case .image(let image):
                    guard let imageData = image.jpegData(compressionQuality: 0.5) else { return }
                    let imageURL = try await imageService.uploadImage(imageData: imageData,
                                                                      in: "images/\(UUID().uuidString).jpg")
                    let dataToSave = ImageData(id: documentID, imageURL: imageURL.absoluteString)
                    try await firestoreService.updateDocument(data: dataToSave,
                                                              in: collection,
                                                              documentId: documentID)
                    
                case .video(let videoURL):
                    let videoData = try Data(contentsOf: videoURL)
                    let videoURL = try await imageService.uploadVideo(videoData: videoData,
                                                                      in: "videos/\(UUID().uuidString).mov")
                    let dataToSave = VideoData(id: documentID, videoURL: videoURL.absoluteString)
                    try await firestoreService.updateDocument(data: dataToSave,
                                                              in: collection,
                                                              documentId: documentID)
            }
        } catch {
            handleError(error)
        }
    }
    
    func fetchDocuments<T: Codable>(from collection: Collection, as type: T.Type) async -> [T] {
        isLoading = true
        defer { isLoading = false }
        
        do {
            return try await firestoreService.fetchDocuments(from: collection, as: type)
        } catch {
            handleError(error)
            return []
        }
    }
    
    func updateDocument<T: Codable>(data: T, in collection: Collection, documentId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await firestoreService.updateDocument(data: data, in: collection, documentId: documentId)
        } catch {
            handleError(error)
        }
    }
    
    func deleteDocument(in collection: Collection, documentId: String) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await firestoreService.deleteDocument(in: collection, documentId: documentId)
        } catch {
            handleError(error)
        }
    }
    
    private func handleError(_ error: Error) {
        errorMessage = "Error: \(error.localizedDescription)"
        showAlert = true
    }
}
