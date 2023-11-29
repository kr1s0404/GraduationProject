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
    @StateObject private var locationVM = SuspectLocationViewModel()
    
    var body: some View
    {
        TabView
        {
            FaceDetectionView(faceDetectionVM: faceDetectionVM, locationVM: locationVM)
                .tabItem { Label("分析嫌犯", systemImage: "camera.viewfinder") }
                .cameraSafeArea()
            
            AllSuspectMapView(locationVM: locationVM)
                .tabItem { Label("嫌犯地圖", systemImage: "map.circle.fill") }
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
