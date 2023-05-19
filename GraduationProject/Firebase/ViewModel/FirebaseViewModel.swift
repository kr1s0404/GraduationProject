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
    func fetch() async throws -> User {
        let query = database.collection(Collections.Users.rawValue)
        return try await firebaseService.fetch(of: User.self, with: query)
    }
}
