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
            PoseEstimationView(viewModel: cameraVM)
                .ignoresSafeArea()
                .tabItem { Label("姿態辨識", systemImage: "camera") }
            
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
