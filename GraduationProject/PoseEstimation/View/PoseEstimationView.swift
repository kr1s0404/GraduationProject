//
//  PoseEstimationView.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import SwiftUI
import AVFoundation

struct PoseEstimationView: View
{
    @ObservedObject var viewModel: CameraViewModel
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                ZStack
                {
                    CameraUIViewRepresentable(captureSession: viewModel.captureSession)
                    
                    DrawingJointView(joints: viewModel.joints)
                }
                .onAppear(perform: viewModel.startSession)
                .onDisappear(perform: viewModel.endSession)
                
                ScrollView(.horizontal, showsIndicators: false)
                {
                    HStack(spacing: 20)
                    {
                        ForEach(Array(viewModel.savedPoses.enumerated()), id: \.offset) { index, pose in
                            
                            
                            VStack
                            {
                                NavigationLink(value: pose) {
                                    Text("查看")
                                }
                                
                                if index < viewModel.matchConfidences.count {
                                    let confidencesRate = viewModel.matchConfidences[index] * 100
                                    Text("\(viewModel.matchConfidences[index] * 100, specifier: "%.2f")%")
                                        .font(.caption)
                                        .background(confidencesRate > 80 ? .green : .white)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationDestination(for: [CGPoint].self) { pose in
                PoseView(joints: pose)
                    .background(.white)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Capture Pose") {
                        viewModel.captureCurrentPose()
                    }
                    .disabled(viewModel.savedPoses.count >= 5)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Reset Poses") {
                        viewModel.resetSavedPoses()
                    }
                }
            }
        }
    }
}
