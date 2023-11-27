//
//  ComparisonView.swift
//  GraduationProject
//
//  Created by Kris on 11/2/23.
//

import SwiftUI

struct ComparisonView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    
    var body: some View
    {
        VStack
        {
            List(faceDetectionVM.suspectList) { suspect in
                NavigationLink {
                    SuspectMapView(suspect: suspect)
                } label: {
                    suspectLabel(suspect: suspect)
                        .overlay(alignment: .topTrailing) {
                            if let suspectScore = suspect.score {
                                scoreNumber(score: suspectScore)
                            }
                        }
                }
            }
        }
        .overlay { if faceDetectionVM.isLoading { ProgressView() } }
    }
}

extension ComparisonView {
    @ViewBuilder
    private func scoreNumber(score: Double) -> some View {
        Text("\(score, specifier: "%.2f")")
            .bold()
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(score > 70 ? .green : .red)
            .cornerRadius(30)
    }
    
    @ViewBuilder
    private func suspectLabel(suspect: Suspect) -> some View {
        HStack
        {
            Image(uiImage: suspect.uiImage)
                .resizable()
                .scaledToFit()
            
            if let capturedImage = faceDetectionVM.capturedImage {
                Image(uiImage: capturedImage)
                    .resizable()
                    .scaledToFit()
            }
            
            if let detectedImage = suspect.detectedImage {
                Image(uiImage: detectedImage)
                    .resizable()
                    .scaledToFit()
            } else {
                ProgressView()
            }
        }
    }
}
