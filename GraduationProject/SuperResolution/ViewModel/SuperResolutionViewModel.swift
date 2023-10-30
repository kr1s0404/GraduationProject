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
    
    private var resizedImageSize: CGSize = CGSize(width: 512, height: 512)
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            self.model = try SuperResolutionModel(configuration: config)
        } catch {
            print("Error loading model: \(error)")
        }
    }
    
    func makeImageSuperResolution(from image: UIImage) {
        guard let model = model else {
            print("Model is nil")
            return
        }
        let originalImageSize = image.size
        guard let resizedImage = image.resizeImageToExactSize(to: resizedImageSize) else {
            print("Model can not be resize")
            return
        }
        guard let imageToBuffer = resizedImage.convertToBuffer() else {
            print("Failed to convert image to buffer")
            return
        }
        do {
            let prediction = try model.prediction(x_1: imageToBuffer)
            let srImage = imageFromBuffer(prediction.activation_out)
            self.imageAfterSR = srImage?.resizeImageToExactSize(to: originalImageSize)
        } catch {
            print("Error during image super-resolution: \(error)")
        }
    }
    
    func imageFromBuffer(_ pixelBuffer: CVPixelBuffer) -> UIImage? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
        
        return UIImage(cgImage: cgImage)
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
        
        let newSize = CGSize(width: targetWidth, height: targetHeight)
        let rectangle = CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight)
        
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: rectangle)
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
