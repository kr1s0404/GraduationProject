//
//  ContentView.swift
//  GraduationProject
//
//  Created by Kris on 5/15/23.
//

import SwiftUI
import ARKit

struct ContentView: View
{
    @StateObject private var cameraVM = CameraViewModel()
    @StateObject private var faceDetectionVM = FaceDetectionViewModel()
    @StateObject private var firestoreVM = FirestoreViewModel()
    
    var body: some View
    {
        TabView
        {
            FaceDetectionView(faceDetectionVM: faceDetectionVM)
                .tabItem { Label("臉部辨識", systemImage: "person") }
                .cameraSafeArea()
            
            SuperResolutionView()
                .tabItem { Label("超解析度還原", systemImage: "wand.and.stars.inverse") }
            
            SuspectView(faceDetectionVM: faceDetectionVM, firestoreVM: firestoreVM)
                .tabItem { Label("分析嫌犯", systemImage: "waveform") }
            
            ImageUploadView(firestoreVM: firestoreVM)
                .tabItem { Label("上傳圖片", systemImage: "photo") }
            
            PoseEstimationView(viewModel: cameraVM)
                .tabItem { Label("姿態辨識", systemImage: "camera") }
                .cameraSafeArea()
        }
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
