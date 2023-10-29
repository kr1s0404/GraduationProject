//
//  ImageUploadView.swift
//  GraduationProject
//
//  Created by Kris on 10/29/23.
//

import SwiftUI
import AVKit

struct ImageUploadView: View
{
    @ObservedObject var firestoreVM: FirestoreViewModel
    
    @State private var showImagePicker: Bool = false
    @State private var selectedMedia: Media?
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                if let media = selectedMedia {
                    switch media {
                        case .image(let image):
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFit()
                        case .video(let url):
                            VideoPlayer(player: AVPlayer(url: url))
                    }
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(media: $selectedMedia)
            }
            .toolbar {
                selectMediaButton
                uploadMediaButton
            }
        }
    }
    
    private func uploadMedia(_ media: Media) {
        switch media {
            case .image(let image):
                Task {
                    await firestoreVM.uploadImageAndCreateDocument(image: image, in: Collection.Images)
                }
            case .video(let url):
                
                break
        }
    }
}

extension ImageUploadView {
    @ToolbarContentBuilder
    private var selectMediaButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Select Media") {
                showImagePicker.toggle()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var uploadMediaButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Upload Media") {
                guard let media = selectedMedia else { return }
                uploadMedia(media)
            }
            .disabled(selectedMedia == nil)
        }
    }
}


struct ImageUploadView_Previews: PreviewProvider
{
    static var previews: some View
    {
        ImageUploadView(firestoreVM: FirestoreViewModel())
    }
}
