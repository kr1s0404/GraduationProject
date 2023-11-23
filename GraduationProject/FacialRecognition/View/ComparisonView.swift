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
    
    @State var suspctImageAfterSR: UIImage?
    @State var cuurentImageAfterSR: UIImage?
    
    var body: some View
    {
        VStack
        {
            if let suspectImage = faceDetectionVM.suspect?.uiImage,
               let currentImage = faceDetectionVM.capturedImage {
                HStack
                {
                    Image(uiImage: suspectImage)
                        .resizable()
                        .scaledToFit()
                }
                
                HStack
                {
                    Image(uiImage: currentImage)
                        .resizable()
                        .scaledToFit()
                }
            }
            
            Button {
                faceDetectionVM.compareFacialFeature()
            } label: {
                Text("比對")
            }
            
            Text("\(faceDetectionVM.possibilty, specifier: "%.2f")%")
                .bold()
                .foregroundColor(.white)
                .frame(width: 130, height: 50)
                .background(faceDetectionVM.possibilty > 80 ? .green : .red)
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
