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
        
        // Ensure the pixelData array is the correct size
        let pixelDataSize = width * height * bytesPerPixel
        var pixelData = [UInt8](repeating: 0, count: pixelDataSize)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(data: &pixelData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else { return }
        
        context.draw(cgImage, in: CGRect(origin: .zero, size: size))
        
        buffer.removeAll(keepingCapacity: true)
        
        // Using a for loop to avoid using a potentially unsafe pointer
        for i in 0 ..< height {
            for j in 0 ..< width {
                let pixelIndex = i * width + j
                let offset = pixelIndex * bytesPerPixel
                guard offset + 2 < pixelDataSize else { continue }
                
                buffer.append(Double(pixelData[offset]))     // Red
                buffer.append(Double(pixelData[offset + 1])) // Green
                buffer.append(Double(pixelData[offset + 2])) // Blue
            }
        }
    }
    
    func preWhiten(input: inout [Double], output: inout MLMultiArray) {
        guard !input.isEmpty else { return } // Ensure input is not empty
        
        let inputCount = vDSP_Length(input.count)
        
        // Calculate mean using Accelerate
        var mean = 0.0
        vDSP_meanvD(input, 1, &mean, inputCount)
        
        // Subtract mean from input values in place
        var negativeMean = -mean
        input.withUnsafeMutableBufferPointer { buffer in
            vDSP_vsaddD(buffer.baseAddress!, 1, &negativeMean, buffer.baseAddress!, 1, inputCount)
        }
        
        // Calculate the sum of squares of input using Accelerate
        var sumOfSquares = 0.0
        vDSP_svesqD(input, 1, &sumOfSquares, inputCount)
        
        // Calculate standard deviation
        let stdDev = sqrt(sumOfSquares / Double(input.count))
        
        // Adjust the standard deviation with max(stdDev, 1.0/sqrt(Double(input.count)))
        let stdDevAdj = max(stdDev, 1.0 / sqrt(Double(input.count)))
        
        // Divide input by stdDevAdj and convert to MLMultiArray
        var scaleFactor = 1.0 / stdDevAdj
        vDSP_vsmulD(input, 1, &scaleFactor, &input, 1, inputCount)
        
        // Ensure MLMultiArray is of the correct shape and type before assignment
        guard output.count == input.count else {
            print("Output MLMultiArray does not match the input dimensions.")
            return
        }
        
        // Assign values to output MLMultiArray
        for (index, value) in input.enumerated() {
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
