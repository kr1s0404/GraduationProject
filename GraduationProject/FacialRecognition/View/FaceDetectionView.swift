//
//  FaceDetectionView.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import CoreVideo

struct FaceDetectionView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    
    var body: some View
    {
        NavigationStack
        {
            GeometryReader { geometry in
                ZStack(alignment: .bottom)
                {
                    CameraUIViewRepresentable(captureSession: faceDetectionVM.captureSession)
                        .ignoresSafeArea()
                    
                    FaceBoundingBoxView(faceDetectionVM: faceDetectionVM)
                    
                    
                    HStack
                    {
                        Button {
                            faceDetectionVM.captureFace()
                        } label: {
                            Circle()
                                .foregroundColor(.white)
                                .frame(width: 50, height: 50)
                                .padding(10)
                        }
                        
                        Text("\(faceDetectionVM.possibilty)")
                            .bold()
                            .foregroundColor(.white)
                            .frame(width: 130, height: 50)
                            .background(faceDetectionVM.possibilty > 80 ? .green : .red)
                            .cornerRadius(15)
                    }
                }
                .alert(faceDetectionVM.errorMessage, isPresented: $faceDetectionVM.showAlert, actions: { Text("OK") })
            }
        }
    }
}
