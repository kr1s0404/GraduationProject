//
//  FaceDetectionView.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI

struct FaceDetectionView: View
{
    @StateObject private var faceCameraVM = FaceCameraViewModel()
    
    var body: some View
    {
        GeometryReader { geometry in
            ZStack
            {
                CameraUIViewRepresentable(captureSession: faceCameraVM.captureSession)
                    .ignoresSafeArea()
                
                ForEach(faceCameraVM.faceBoundingBoxes, id: \.self) { box in
                    GeometryReader { faceGeometry in
                        let convertedBox = convertBoundingBox(box, from: geometry.size, to: faceGeometry.size)
                        Rectangle()
                            .stroke(Color.red, lineWidth: 2)
                            .frame(width: convertedBox.width, height: convertedBox.height)
                            .offset(x: convertedBox.minX, y: convertedBox.minY)
                    }
                }
            }
        }
    }
    
    private func convertBoundingBox(_ box: CGRect, from parentSize: CGSize, to targetSize: CGSize) -> CGRect {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - box.origin.x - box.width) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - box.origin.y - box.height) * scaleY // Inverting Y-axis for SwiftUI
        let width = box.width * scaleX
        let height = box.height * scaleY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
