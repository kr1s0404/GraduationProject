//
//  FaceBoundingBox.swift
//  GraduationProject
//
//  Created by Kris on 11/4/23.
//

import SwiftUI

struct FaceBoundingBoxView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    
    var body: some View
    {
        ForEach(faceDetectionVM.currentFaceData, id: \.boundingBox) { faceData in
            GeometryReader { faceGeometry in
                let convertedBox = faceDetectionVM.convertBoundingBox(faceData.boundingBox, to: faceGeometry.size)
                
                VStack
                {
                    Rectangle()
                        .stroke(Color.red, lineWidth: 2)
                        .frame(width: convertedBox.width, height: convertedBox.height)
                        .offset(x: convertedBox.minX, y: convertedBox.minY)
                        .padding(.bottom)
                    
                    Text("\(faceDetectionVM.possibilty)")
                        .foregroundColor(faceDetectionVM.possibilty > 80 ? .green : .red)
                }
            }
        }
    }
}
