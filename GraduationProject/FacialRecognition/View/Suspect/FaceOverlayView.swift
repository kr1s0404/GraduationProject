//
//  FaceOverlayView.swift
//  GraduationProject
//
//  Created by Kris on 11/4/23.
//

import SwiftUI

struct FaceOverlayView: View
{
    let faceData: FaceData
    let imageSize: CGSize
    
    var body: some View
    {
        GeometryReader { geometry in
            let convertedBox = convertBoundingBox(faceData.boundingBox, to: imageSize)
            
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: convertedBox.width, height: convertedBox.height)
                .offset(x: convertedBox.minX, y: convertedBox.minY)
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
}
