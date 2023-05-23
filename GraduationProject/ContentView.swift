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
        NavigationView
        {
            VStack(spacing: 20)
            {
                if let users = firebaseViewModel.fetchedUsers {
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
                
                NavigationLink {
                    ImagePicker(image: $firebaseViewModel.selectedImage)
                        .onChange(of: firebaseViewModel.selectedImage) { newValue in
                            firebaseViewModel.selectedImage = newValue
                        }
                } label: {
                    Text("Select Iamge")
                        .font(.largeTitle)
                }

                if let image = firebaseViewModel.selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
                
                Button {
                    Task {
                        do {
                            try await firebaseViewModel.uploadImage()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Upload Image")
                        .font(.largeTitle)
                }
                
                Button {
                    Task {
                        do {
                            try await firebaseViewModel.fetchImages()
                        } catch {
                            print(error)
                        }
                    }
                } label: {
                    Text("Fetch Image")
                        .font(.largeTitle)
                }
                
                ForEach(firebaseViewModel.fetchedImages, id: \.self) { image in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100, height: 100)
                }
            }
            .animation(.spring(), value: firebaseViewModel.isLoading)
            .overlay {
                ProgressView()
                    .scaleEffect(2)
                    .frame(width: 150, height: 150)
                    .background(Material.ultraThinMaterial)
                    .cornerRadius(25)
                    .opacity(firebaseViewModel.isLoading ? 1 : 0)
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
