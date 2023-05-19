//
//  ContentView.swift
//  GraduationProject
//
//  Created by Kris on 5/15/23.
//

import SwiftUI

struct ContentView: View
{
    @StateObject var firebaseManager = FireBaseManager()
    
    var body: some View
    {
        VStack
        {
            Button {
                firebaseManager.createUser()
            } label: {
                Text("TEST")
                    .font(.largeTitle)
            }
        }
        .alert("Error", isPresented: $firebaseManager.showError) {
            Text("OK")
        } message: {
            Text(firebaseManager.errorMessage)
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
