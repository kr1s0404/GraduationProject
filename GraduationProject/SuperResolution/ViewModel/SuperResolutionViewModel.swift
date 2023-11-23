//
//  SuperSolutionViewModel.swift
//  GraduationProject
//
//  Created by Kris on 10/30/23.
//

import SwiftUI
import CoreML
import CoreImage

final class SuperResolutionViewModel: ObservableObject
{
    @Published var model: SuperResolutionModel?
    @Published var imageAfterSR: UIImage?
    
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    private let resizedImageSize: CGSize = CGSize(width: 512, height: 512)
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                self.model = try SuperResolutionModel(configuration: .init())
            } catch {
                self.handleError(errorMessage: "Error loading model: \(error.localizedDescription)")
            }
        }
    }
    
    func makeImageSuperResolution(from image: UIImage, completion: @escaping (UIImage?) -> Void) {
        self.isLoading = true
        
        guard let model = model else {
            handleError(errorMessage: "Model is not available.")
            completion(nil)
            return
        }
        
        let originalImageSize = image.size
        guard let resizedImage = image.resized(to: resizedImageSize) else {
            handleError(errorMessage: "Failed to resize image.")
            completion(nil)
            return
        }
        
        guard let imageToBuffer = resizedImage.toCVPixelBuffer() else {
            handleError(errorMessage: "Failed to convert image to buffer.")
            completion(nil)
            return
        }
        
        // Perform the image processing in a background queue
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let prediction = try model.prediction(x: imageToBuffer)
                let srImage = self.imageFromBuffer(prediction.activation_out)
                let processedImage = srImage?.resized(to: originalImageSize)
                DispatchQueue.main.async {
                    self.isLoading = false
                    completion(processedImage)
                }
            } catch {
                self.handleError(errorMessage: "Error during image super-resolution: \(error)")
                completion(nil)
            }
        }
    }
    
    func imageFromBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent)
        else {
            handleError(errorMessage: "Failed to create image from buffer.")
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
    
    private func handleError(errorMessage: String) {
        DispatchQueue.main.async {
            self.showAlert.toggle()
            self.errorMessage = errorMessage
            self.isLoading = false
        }
    }
}
