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
    @ObservedObject var locationVM: SuspectLocationViewModel
    
    var body: some View
    {
        NavigationStack
        {
            ZStack(alignment: .bottom)
            {
                CameraUIViewRepresentable(captureSession: faceDetectionVM.captureSession)
                    .ignoresSafeArea()
                
                NavigationLink(isActive: $faceDetectionVM.showComparisonView) {
                    ComparisonView(faceDetectionVM: faceDetectionVM, locationVM: locationVM)
                } label: {
                    EmptyView()
                }
                
                Button {
                    faceDetectionVM.captureFace()
                } label: {
                    Circle()
                        .foregroundColor(.white)
                        .frame(width: 50, height: 50)
                        .padding(10)
                }
            }
            .alert(faceDetectionVM.errorMessage, isPresented: $faceDetectionVM.showAlert, actions: { Text("OK") })
        }
    }
}
