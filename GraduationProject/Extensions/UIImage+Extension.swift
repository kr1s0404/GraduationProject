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
    func getPixelData(buffer: inout [Double]) {
        guard let cgImage = self.cgImage else { return }
        
        let size = self.size
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let bitsPerComponent = 8
        
        var pixelData = [UInt8](repeating: 0, count: width * height * bytesPerPixel)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        buffer.removeAll(keepingCapacity: true) // Ensure buffer is empty and has capacity
        
        // Using pointer to directly manipulate pixel data
        pixelData.withUnsafeBufferPointer { ptr in
            let totalPixels = width * height
            buffer.reserveCapacity(totalPixels * 3) // Reserve space for RGB components
            
            for i in 0 ..< totalPixels {
                let offset = i * bytesPerPixel
                buffer.append(Double(ptr[offset]))     // Red
                buffer.append(Double(ptr[offset + 1])) // Green
                buffer.append(Double(ptr[offset + 2])) // Blue
            }
        }
    }
    
    
    func prewhiten(input: inout [Double], output: inout MLMultiArray) {
        // Calculate mean using Accelerate
        var mean = 0.0
        vDSP_meanvD(input, 1, &mean, vDSP_Length(input.count))
        
        // Subtract mean from input values in place
        var negativeMean = -mean
        vDSP_vsaddD(input, 1, &negativeMean, &input, 1, vDSP_Length(input.count))
        
        // Calculate the sum of squares of input using Accelerate
        var sumOfSquares = 0.0
        vDSP_svesqD(input, 1, &sumOfSquares, vDSP_Length(input.count))
        
        // Calculate standard deviation
        let stdDev = sqrt(sumOfSquares / Double(input.count))
        
        // Adjust the standard deviation with max(stdDev, 1/sqrt(inputCount))
        let stdDevAdj = max(stdDev, 1.0 / sqrt(Double(input.count)))
        
        // Divide input by stdDevAdj and convert to MLMultiArray
        let scaleFactor = 1.0 / stdDevAdj
        var result = input // Use a local variable to store the result temporarily
        
        vDSP_vsmulD(input, 1, [scaleFactor], &result, 1, vDSP_Length(input.count))
        
        // Assign values to output MLMultiArray
        for (index, value) in result.enumerated() {
            output[index] = NSNumber(value: value)
        }
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
                                         kCVPixelFormatType_32BGRA,
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
