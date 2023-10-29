//
//  ImageService.swift
//  GraduationProject
//
//  Created by Kris on 10/29/23.
//

import SwiftUI
import FirebaseStorage

final class ImageService: ImageServiceProtocol
{
    private let storage = Storage.storage()
    
    func uploadImage(imageData: Data, in path: String) async throws -> URL {
        let storageRef = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        let _ = try await storageRef.putDataAsync(imageData, metadata: metadata)
        return try await storageRef.downloadURL()
    }
}
