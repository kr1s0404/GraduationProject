//
//  SuspectViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/2/23.
//

import SwiftUI
import Vision

final class SuspectViewModel: ObservableObject
{
    @Published var selectedImage: UIImage?
    
    @Published var fetchedData: [ImageData]?
    @Published var detectedFaceData: FaceData?
    
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    
    @MainActor
    func convertAndDetectImage(from urlString: String) async {
        guard let imageURL = URL(string: urlString) else { return }
        let session = URLSession.shared
        let request = URLRequest(url: imageURL)
        
        do {
            let (data, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                if let image = UIImage(data: data) {
                    selectedImage = image
                    detectFaces(in: image)
                }
            } else {
                print("Invalid response or status code")
            }
        } catch {
            print("Error fetching image: \(error)")
        }
    }
    
    private func detectFaces(in image: UIImage) {
        guard let pixelBuffer = image.convertToBuffer() else { return }
        let requestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try requestHandler.perform([self.faceLandmarksRequest])
            if let results = self.faceLandmarksRequest.results {
                detectedFaceData = results.first.map { FaceData(boundingBox: $0.boundingBox, landmarks: $0.landmarks) }
            }
        } catch {
            print("Face landmarks detection failed: \(error.localizedDescription)")
        }
    }
}
