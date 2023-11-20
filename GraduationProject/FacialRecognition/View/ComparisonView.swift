//
//  ComparisonView.swift
//  GraduationProject
//
//  Created by Kris on 11/21/23.
//

import SwiftUI

struct ComparisonView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    
    var body: some View
    {
        VStack
        {
            if let suspectImage = faceDetectionVM.suspectImage,
               let currentImage = faceDetectionVM.capturedImage {
                Image(uiImage: suspectImage.uiImage)
                    .resizable()
                    .scaledToFit()
                
                Image(uiImage: currentImage)
                    .resizable()
                    .scaledToFit()
            }
            
            Button {
                faceDetectionVM.compareFacialFeature()
            } label: {
                Text("比對")
            }
            
            Text("\(faceDetectionVM.possibilty)")
                .bold()
                .foregroundColor(.white)
                .frame(width: 130, height: 50)
                .background(faceDetectionVM.possibilty > 0.8 ? .green : .red)
                .cornerRadius(15)
        }
    }
}

struct ComparisonView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ComparisonView(faceDetectionVM: FaceDetectionViewModel())
    }
}
