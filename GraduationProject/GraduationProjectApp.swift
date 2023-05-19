//
//  GraduationProjectApp.swift
//  GraduationProject
//
//  Created by Kris on 5/15/23.
//

import SwiftUI
import FirebaseCore

@main
struct GraduationProjectApp: App
{
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene
    {
        WindowGroup
        {
            ContentView()
        }
    }
}
