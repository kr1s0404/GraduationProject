//
//  ImageServiceProtocol.swift
//  GraduationProject
//
//  Created by Kris on 10/29/23.
//

import Foundation
import FirebaseStorage

protocol ImageServiceProtocol {
    func uploadImage(imageData: Data, in path: String) async throws -> URL
}
