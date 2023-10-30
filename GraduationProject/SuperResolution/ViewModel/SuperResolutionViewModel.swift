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
        do {
            let config = MLModelConfiguration()
            self.model = try SuperResolutionModel(configuration: config)
        } catch {
            handleError(errorMessage: "Error loading model: \(error.localizedDescription)")
        }
    }
    
    func makeImageSuperResolution(from image: UIImage) {
        isLoading = true
        defer { isLoading = false }
        
        guard let model = model else {
            handleError(errorMessage: "Model is not available.")
            return
        }
        
        let originalImageSize = image.size
        guard let resizedImage = image.resizeImageToExactSize(to: resizedImageSize) else {
            handleError(errorMessage: "Failed to resize image.")
            return
        }
        
        guard let imageToBuffer = resizedImage.convertToBuffer() else {
            handleError(errorMessage: "Failed to convert image to buffer.")
            return
        }
        
        do {
            let prediction = try model.prediction(x: imageToBuffer)
            let srImage = imageFromBuffer(prediction.activation_out)
            self.imageAfterSR = srImage?.resizeImageToExactSize(to: originalImageSize)
        } catch {
            handleError(errorMessage: "Super Resolution Error: \(error.localizedDescription)")
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
        showAlert.toggle()
        self.errorMessage = errorMessage
    }
}

extension UIImage {
    func convertToBuffer() -> CVPixelBuffer? {
        let attributes = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        
        var pixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(self.size.width),
                                         Int(self.size.height), kCVPixelFormatType_32ARGB,
                                         attributes, &pixelBuffer)
        
        guard status == kCVReturnSuccess, let pixelBuffer = pixelBuffer else {
            print("Failed to create pixel buffer")
            return nil
        }
        
        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0)) }
        
        guard let pixelData = CVPixelBufferGetBaseAddress(pixelBuffer) else {
            return nil
        }
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData, width: Int(self.size.width),
                                      height: Int(self.size.height), bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(pixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            return nil
        }
        
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height))
        UIGraphicsPopContext()
        
        return pixelBuffer
    }
    
    func resizeImageToExactSize(to size: CGSize) -> UIImage? {
        let targetWidth = size.width
        let targetHeight = size.height
        
        let rectangle = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: rectangle)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}