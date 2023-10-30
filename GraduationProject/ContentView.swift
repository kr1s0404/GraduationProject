//
//  ContentView.swift
//  GraduationProject
//
//  Created by Kris on 5/15/23.
//

import SwiftUI

struct ContentView: View
{
    @StateObject var cameraVM = CameraViewModel()
    @StateObject var firestoreVM = FirestoreViewModel()
    
    var body: some View
    {
        TabView
        {
            SuperResolutionView()
                .tabItem { Label("超解析度還原", systemImage: "photo") }
            
            ImageUploadView(firestoreVM: firestoreVM)
                .tabItem { Label("上傳圖片", systemImage: "photo") }
            
            PoseEstimationView(viewModel: cameraVM)
                .tabItem { Label("姿態辨識", systemImage: "camera") }
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
