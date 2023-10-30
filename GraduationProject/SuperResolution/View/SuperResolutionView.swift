//
//  SuperResolutionView.swift
//  GraduationProject
//
//  Created by Kris on 10/30/23.
//

import SwiftUI

struct SuperResolutionView: View
{
    @StateObject var superResolutionVM = SuperResolutionViewModel()
    
    @State var showMediaPicker: Bool = false
    @State var selectedMeida: Media?
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                if let media = selectedMeida {
                    switch media {
                        case .image(let image):
                            ScrollView
                            {
                                mediaContentView(image: image)
                            }
                            .toolbar { makeImageSuperResolutionButton(image: image) }
                        case .video( _):
                            Text("Can not select video")
                                .foregroundColor(.red)
                    }
                }
            }
            .alert(superResolutionVM.errorMessage,
                   isPresented: $superResolutionVM.showAlert,
                   actions: { Text("OK") })
            .overlay { if superResolutionVM.isLoading { loadingSpineer } }
            .sheet(isPresented: $showMediaPicker) { MediaPicker(media: $selectedMeida) }
            .toolbar { showMediaPickerButton }
        }
    }
}

extension SuperResolutionView {
    @ToolbarContentBuilder
    private func makeImageSuperResolutionButton(image: UIImage) -> some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("超解析度還原") { superResolutionVM.makeImageSuperResolution(from: image) }
        }
    }
    
    @ToolbarContentBuilder
    private var showMediaPickerButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("開啟相簿") { showMediaPicker.toggle() }
        }
    }
    
    @ViewBuilder
    private func mediaContentView(image: UIImage) -> some View {
        VStack
        {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
            
            Divider()
                .padding(.vertical)
            
            if let imageAfterSuperResolution = superResolutionVM.imageAfterSR {
                Image(uiImage: imageAfterSuperResolution)
                    .resizable()
                    .scaledToFit()
            }
        }
    }
    
    @ViewBuilder
    private var loadingSpineer: some View {
        ProgressView("Converting Image...")
            .frame(width: 250, height: 250)
            .background(Material.ultraThinMaterial)
            .cornerRadius(25)
            .foregroundColor(.black)
    }
}

struct SuperResolutionView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SuperResolutionView()
    }
}
