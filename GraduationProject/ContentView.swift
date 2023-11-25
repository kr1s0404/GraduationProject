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
    
    var body: some View
    {
        TabView
        {
            FaceDetectionView(faceDetectionVM: faceDetectionVM)
                .tabItem { Label("分析嫌犯", systemImage: "camera.viewfinder") }
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
