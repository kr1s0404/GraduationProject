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
    
    @MainActor
    func create() async throws -> User {
        try await firebaseService.create(User(id: "", firstName: "test", lastName: "test", birthYear: 1234),
                                         to: Collections.Users.rawValue)
    }
    
    @MainActor
    func fetch(by id: String) async throws -> User {
        let query = database
            .collection(Collections.Users.rawValue)
            .whereField("id", isEqualTo: id)
        
        return try await firebaseService.fetch(of: User.self, with: query)
    }
    
    @MainActor
    func fetchAll() async throws -> [User] {
        let query = database
            .collection(Collections.Users.rawValue)
        
        return try await firebaseService.fetchAll(of: User.self, with: query)
    }
    
    @MainActor
    func update(user: User) async throws -> User {
        try await firebaseService.update(User(id: user.id, firstName: "y", lastName: "z", birthYear: 9876),
                                         to: Collections.Users.rawValue)
    }
    
    @MainActor
    func delete(user: User) async throws {
        try await firebaseService.delete(user, to: Collections.Users.rawValue)
    }
}
