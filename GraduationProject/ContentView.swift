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
    
    var body: some View
    {
        PoseEstimationView(viewModel: cameraVM)
            .ignoresSafeArea()
    }
}

struct ContentView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ContentView()
    }
}
