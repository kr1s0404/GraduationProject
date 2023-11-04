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
                    
                    Button {
                        faceDetectionVM.captureFace()
                    } label: {
                        Circle()
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .padding(.bottom, 5)
                    }
                }
                .alert(faceDetectionVM.errorMessage, isPresented: $faceDetectionVM.showAlert, actions: { Text("OK") })
            }
        }
    }
}
