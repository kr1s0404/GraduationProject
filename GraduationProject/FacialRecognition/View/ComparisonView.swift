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
        NavigationStack
        {
            VStack
            {
                List(faceDetectionVM.suspectList) { suspect in
                    HStack
                    {
                        Image(uiImage: suspect.uiImage)
                            .resizable()
                            .scaledToFit()
                        
                        if let detectedImage = suspect.detectedImage {
                            Image(uiImage: detectedImage)
                                .resizable()
                                .scaledToFit()
                        } else {
                            ProgressView()
                        }
                    }
                    .overlay(alignment: .topTrailing) {
                        if let suspectScore = suspect.score {
                            scoreNumber(score: suspectScore)
                        }
                    }
                }
            }
            .overlay { if faceDetectionVM.isLoading { ProgressView() } }
        }
    }
}

extension ComparisonView {
    @ViewBuilder
    private func scoreNumber(score: Double) -> some View {
        Text("\(score * 100, specifier: "%.2f")")
            .bold()
            .foregroundColor(.white)
            .frame(width: 60, height: 60)
            .background(score > 0.7 ? .green : .red)
            .cornerRadius(30)
    }
}
