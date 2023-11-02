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
    @StateObject var cameraVM = CameraViewModel()
    @StateObject var firestoreVM = FirestoreViewModel()
    @StateObject var suspectVM = SuspectViewModel()
    
    var body: some View
    {
        TabView
        {
            FaceDetectionView(suspectVM: suspectVM)
                .tabItem { Label("臉部辨識", systemImage: "person") }
                .cameraSafeArea()
            
            SuperResolutionView()
                .tabItem { Label("超解析度還原", systemImage: "wand.and.stars.inverse") }
            
            SuspectView(suspectVM: suspectVM, firestoreVM: firestoreVM)
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
