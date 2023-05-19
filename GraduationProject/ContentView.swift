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
    
    @State var x: User?
    @State var y: [User]?
    @State var z: User?
    
    var body: some View
    {
        VStack
        {
            
            if let x = x {
                Text(x.id)
            }
            
            if let y = y {
                ForEach(y, id: \.id) { yy in
                    Text(yy.id)
                        .onTapGesture {
                            Task {
                                do {
                                    self.z = try await firebaseViewModel.update(user: yy)
                                } catch {
                                    print(error)
                                }
                            }
                        }
                }
            }
            
            Button {
                Task {
                    do {
                        self.x = try await firebaseViewModel.create()
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Create")
                    .font(.largeTitle)
            }
            
            Button {
                Task {
                    do {
                        self.y = try await firebaseViewModel.fetchAll()
                    } catch {
                        print(error)
                    }
                }
            } label: {
                Text("Fetch")
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
