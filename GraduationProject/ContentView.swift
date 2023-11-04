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
    @StateObject private var faceDetectionVM = FaceDetectionViewModel()
    @StateObject private var firestoreVM = FirestoreViewModel()
    
    var body: some View
    {
        TabView
        {
            SuspectView(faceDetectionVM: faceDetectionVM, firestoreVM: firestoreVM)
                .tabItem { Label("分析嫌犯", systemImage: "waveform") }
            
            FaceDetectionView(faceDetectionVM: faceDetectionVM)
                .tabItem { Label("臉部辨識", systemImage: "person") }
                .cameraSafeArea()
            
            SuperResolutionView()
                .tabItem { Label("超解析度還原", systemImage: "wand.and.stars.inverse") }
            
            ImageUploadView(firestoreVM: firestoreVM)
                .tabItem { Label("上傳圖片", systemImage: "photo") }
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
