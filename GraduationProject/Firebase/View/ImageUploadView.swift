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
    @ObservedObject var firestoreVM: FirestoreManager
    
    @State private var showMediaPicker: Bool = false
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
            .overlay {
                if firestoreVM.isLoading {
                    LoadingSpineer
                }
            }
            .sheet(isPresented: $showMediaPicker) {
                MediaPicker(media: $selectedMedia)
            }
            .toolbar {
                selectMediaButton
                uploadMediaButton
            }
        }
    }
    
    private func uploadMedia(_ media: Media) async {
        switch media {
            case .image( _):
                await firestoreVM.uploadMediaAndCreateDocument(media: media, in: Collection.Images)
            case .video( _):
                await firestoreVM.uploadMediaAndCreateDocument(media: media, in: Collection.Videos)
                break
        }
    }
}

extension ImageUploadView {
    @ToolbarContentBuilder
    private var selectMediaButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("開啟相簿") {
                showMediaPicker.toggle()
            }
        }
    }
    
    @ToolbarContentBuilder
    private var uploadMediaButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("上傳至後端") {
                guard let media = selectedMedia else { return }
                Task { await uploadMedia(media) }
            }
            .disabled(selectedMedia == nil)
        }
    }
    
    private var LoadingSpineer: some View {
        ProgressView("Loading...")
            .frame(width: 250, height: 250)
            .background(Material.ultraThinMaterial)
            .cornerRadius(25)
            .foregroundColor(.white)
    }
}
