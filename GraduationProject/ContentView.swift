//
//  ContentView.swift
//  GraduationProject
//
//  Created by Kris on 5/15/23.
//

import SwiftUI

struct ContentView: View
{
    @StateObject var firebaseViewModel = FirebaseViewModel()
    
    var body: some View
    {
        VStack
        {
            Button {
                Task {
                }
            } label: {
                Text("TEST")
                    .font(.largeTitle)
            }
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
