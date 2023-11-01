//
//  FaceDetectionView.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision

struct FaceDetectionView: View
{
    @StateObject private var faceCameraVM = FaceDetectionViewModel()
    
    var body: some View
    {
        GeometryReader { geometry in
            ZStack
            {
                CameraUIViewRepresentable(captureSession: faceCameraVM.captureSession)
                    .ignoresSafeArea()
                
                ForEach(faceCameraVM.faces, id: \.boundingBox) { faceData in
                    GeometryReader { faceGeometry in
                        let convertedBox = convertBoundingBox(faceData.boundingBox, to: faceGeometry.size)
                        
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: convertedBox.width, height: convertedBox.height)
                            .offset(x: convertedBox.minX, y: convertedBox.minY)
                        
                        if let facePoint = faceData.landmarks?.allPoints?.normalizedPoints {
                            ForEach(facePoint, id: \.self) { point in
                                let boundingBoxSize = CGSize(width: convertedBox.width, height: convertedBox.height)
                                let convertedPoint = convertPoint(point, to: boundingBoxSize)
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 5, height: 5)
                                    .offset(x: convertedPoint.x, y: convertedPoint.y)
                            }
                            .offset(x: convertedBox.minX, y: convertedBox.minY)
                        }
                    }
                }
            }
            .alert(faceCameraVM.errorMessage, isPresented: $faceCameraVM.showAlert, actions: { Text("OK") })
        }
    }
    
    private func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - box.origin.x - box.width) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - box.origin.y - box.height) * scaleY // Inverting Y-axis for SwiftUI
        let width = box.width * scaleX
        let height = box.height * scaleY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func convertPoint(_ point: CGPoint, to targetSize: CGSize) -> CGPoint {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - point.x) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - point.y) * scaleY // Inverting Y-axis for SwiftUI
        
        return CGPoint(x: x, y: y)
    }
}
