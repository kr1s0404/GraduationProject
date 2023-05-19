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
            if var users = firebaseViewModel.fetchedUsers {
                ForEach(users, id: \.id) { user in
                    Text("\(user.firstName) \(user.lastName) - \(user.birthYear)")
                        .onTapGesture {
                            Task {
                                do {
                                    try await firebaseViewModel.delete(user: user)
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
                        firebaseViewModel.createdUser = try await firebaseViewModel.create()
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
                        firebaseViewModel.fetchedUsers = try await firebaseViewModel.fetchAll()
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
