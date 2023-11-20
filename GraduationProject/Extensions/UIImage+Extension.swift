//
//  UIImage+Extension.swift
//  GraduationProject
//
//  Created by Kris on 11/3/23.
//

import UIKit
import CoreML
import Accelerate
import CoreGraphics

extension UIImage {
    func getPixelData() -> [Double] {
        guard let cgImage = self.cgImage else { return [] }
        
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        let pixelDataSize = width * height * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: pixelDataSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return [] }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: self.size))
        
        var buffer = [Double]()
        buffer.reserveCapacity(width * height * 3) // Reserve capacity for RGB values only
        
        for i in 0 ..< height {
            for j in 0 ..< width {
                let pixelIndex = i * width + j
                let offset = pixelIndex * bytesPerPixel
                if offset + 2 < pixelDataSize {
                    buffer.append(Double(pixelData[offset]))     // Red
                    buffer.append(Double(pixelData[offset + 1])) // Green
                    buffer.append(Double(pixelData[offset + 2])) // Blue
                }
            }
        }
        
        return buffer
    }
    
    func preWhiten(input: [Double]?) -> MLMultiArray? {
        guard let input = input else { return nil }
        guard !input.isEmpty else { return nil }
        
        let inputCount = vDSP_Length(input.count)
        var mean = 0.0
        var inputCopy = input // Copy input to a mutable array
        
        vDSP_meanvD(input, 1, &mean, inputCount)
        var negativeMean = -mean
        
        vDSP_vsaddD(inputCopy, 1, &negativeMean, &inputCopy, 1, inputCount)
        
        var sumOfSquares = 0.0
        vDSP_svesqD(inputCopy, 1, &sumOfSquares, inputCount)
        
        let stdDev = sqrt(sumOfSquares / Double(inputCopy.count))
        let stdDevAdj = max(stdDev, 1.0 / sqrt(Double(inputCopy.count)))
        var scaleFactor = 1.0 / stdDevAdj
        
        vDSP_vsmulD(inputCopy, 1, &scaleFactor, &inputCopy, 1, inputCount)
        
        // Attempt to create MLMultiArray
        guard let output = try? MLMultiArray(shape: [1, 160, 160, 3], dataType: .float32) else {
            return nil
        }
        
        // Assign values to output MLMultiArray
        for (index, value) in inputCopy.enumerated() {
            output[index] = NSNumber(value: value)
        }
        
        return output
    }
}

extension UIImage {
    func toCVPixelBuffer() -> CVPixelBuffer? {
        let attrs = [
            kCVPixelBufferCGImageCompatibilityKey: kCFBooleanTrue,
            kCVPixelBufferCGBitmapContextCompatibilityKey: kCFBooleanTrue
        ] as CFDictionary
        var pixelBuffer: CVPixelBuffer?
        let width = Int(self.size.width)
        let height = Int(self.size.height)
        
        let status = CVPixelBufferCreate(kCFAllocatorDefault,
                                         width,
                                         height,
                                         kCVPixelFormatType_32ARGB,
                                         attrs,
                                         &pixelBuffer)
        
        guard status == kCVReturnSuccess, let unwrappedPixelBuffer = pixelBuffer else {
            return nil
        }
        
        CVPixelBufferLockBaseAddress(unwrappedPixelBuffer, [])
        let pixelData = CVPixelBufferGetBaseAddress(unwrappedPixelBuffer)
        
        let rgbColorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: 8,
                                      bytesPerRow: CVPixelBufferGetBytesPerRow(unwrappedPixelBuffer),
                                      space: rgbColorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue) else {
            CVPixelBufferUnlockBaseAddress(unwrappedPixelBuffer, [])
            return nil
        }
        
        context.translateBy(x: 0, y: CGFloat(height))
        context.scaleBy(x: 1.0, y: -1.0)
        
        UIGraphicsPushContext(context)
        self.draw(in: CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        UIGraphicsPopContext()
        CVPixelBufferUnlockBaseAddress(unwrappedPixelBuffer, [])
        
        return unwrappedPixelBuffer
    }
    
    func resized(to newSize: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        self.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return resizedImage
    }
}
