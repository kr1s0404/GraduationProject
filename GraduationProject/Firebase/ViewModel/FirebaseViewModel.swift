//
//  FirebaseViewModel.swift
//  GraduationProject
//
//  Created by Kris on 5/19/23.
//

import SwiftUI

final class FirebaseViewModel: ObservableObject
{
    private let firebaseService = FirebaseService.shared
    private let database = FirebaseService.shared.database
    
    @Published var fetchedUsers: [User]?
    @Published var createdUser: User?
    @Published var updatedUser: User?
    
    @Published var selectedImage: UIImage?
    @Published var fetchedImages: [UIImage] = []
    
    @Published var isLoading: Bool = false
    
    private func updateIsLoading(_ isLoading: Bool) {
        self.isLoading = isLoading
    }
    
    @MainActor
    func create<T: FirebaseIdentifiable>(_ data: T, collection: Collections) async throws -> T {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        return try await firebaseService.create(data, to: collection.rawValue)
    }
    
    @MainActor
    func fetch<T: Codable>(by id: String, collection: Collections) async throws -> T {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let query = database
            .collection(collection.rawValue)
            .whereField("id", isEqualTo: id)
        
        return try await firebaseService.fetch(of: T.self, with: query)
    }
    
    @MainActor
    func fetchAll<T: Codable>(collection: Collections) async throws -> [T] {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let query = database
            .collection(collection.rawValue)
        
        return try await firebaseService.fetchAll(of: T.self, with: query)
    }
    
    @MainActor
    func update<T: FirebaseIdentifiable>(_ data: T, collection: Collections) async throws -> T {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        return try await firebaseService.update(data, to: collection.rawValue)
    }
    
    @MainActor
    func delete<T: FirebaseIdentifiable>(_ data: T, collection: Collections) async throws {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        try await firebaseService.delete(data, to: collection.rawValue)
    }
    
    @MainActor
    func uploadImage() async throws {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        guard let image = self.selectedImage else { return }
        let uploadedImageURL = try await firebaseService.uploadImage(image: image)
        let imageRecord = SuperResolutionImage(id: "", imageURL: uploadedImageURL)
        let _ = try await self.create(imageRecord, collection: Collections.Images)
    }
    
    @MainActor
    func fetchImages() async throws {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let result = try await firebaseService.fetchImages()
        let maxAllowedSize: Int64 = 15 * 1024 * 1024 // 15MB
        self.fetchedImages = []
        for image in result.items {
            image.getData(maxSize: maxAllowedSize, completion: { (data, error) in
                if let error = error { print(error) }
                guard let data = data else { print("no data"); return }
                guard let image = UIImage(data: data) else { print("failed to decode image data"); return }
                withAnimation(.spring()) {
                    self.fetchedImages.append(image)
                }
            })
        }
    }
}

