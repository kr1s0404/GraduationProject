//
//  FaceBoundingBox.swift
//  GraduationProject
//
//  Created by Kris on 11/4/23.
//

import SwiftUI

struct FaceBoundingBoxView: View
{
    @ObservedObject var suspectVM: SuspectViewModel
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    
    var body: some View
    {
        ForEach(faceDetectionVM.faces, id: \.boundingBox) { faceData in
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
                
                if let facePoint = faceData.landmarks?.allPoints?.normalizedPoints {
                    ForEach(facePoint, id: \.self) { point in
                        points(convertedBox: convertedBox, point: point)
                    }
                    .offset(x: convertedBox.minX, y: convertedBox.minY)
                    .onAppear {
                        guard let suspectImage = suspectVM.selectedImage,
                              let suspectImageBuffer = suspectImage.convertToBuffer(),
                              let dectedFace = faceDetectionVM.detectFace(in: suspectImageBuffer)
                        else { return }
                        
                        faceDetectionVM.updatePossibility(for: faceData, with: dectedFace)
                    }
                }
            }
        }
    }
}

extension FaceBoundingBoxView {
    @ViewBuilder
    private func points(convertedBox: CGRect, point: CGPoint) -> some View {
        let boundingBoxSize = CGSize(width: convertedBox.width, height: convertedBox.height)
        let convertedPoint = faceDetectionVM.convertPoint(point, to: boundingBoxSize)
        Circle()
            .fill(Color.white)
            .frame(width: 3, height: 3)
            .offset(x: convertedPoint.x, y: convertedPoint.y)
    }
}
