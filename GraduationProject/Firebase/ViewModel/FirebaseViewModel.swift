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
    func create(user: User? = nil) async throws -> User {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let user = user ?? User(id: "", firstName: "test", lastName: "test", birthYear: 1234)
        return try await firebaseService.create(user, to: Collections.Users.rawValue)
    }
    
    @MainActor
    func fetch(by id: String) async throws -> User {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let query = database
            .collection(Collections.Users.rawValue)
            .whereField("id", isEqualTo: id)
        
        return try await firebaseService.fetch(of: User.self, with: query)
    }
    
    @MainActor
    func fetchAll() async throws -> [User] {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        let query = database
            .collection(Collections.Users.rawValue)
        
        return try await firebaseService.fetchAll(of: User.self, with: query)
    }
    
    @MainActor
    func update(user: User) async throws -> User {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        return try await firebaseService.update(user, to: Collections.Users.rawValue)
    }
    
    @MainActor
    func delete(user: User) async throws {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        try await firebaseService.delete(user, to: Collections.Users.rawValue)
        withAnimation(.spring()) {
            self.fetchedUsers?.removeAll(where: { $0.id == user.id })
        }
    }
    
    @MainActor
    func uploadImage() async throws {
        defer { updateIsLoading(false) }
        updateIsLoading(true)
        
        guard let image = self.selectedImage else { return }
        try await firebaseService.uploadImage(image: image)
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

