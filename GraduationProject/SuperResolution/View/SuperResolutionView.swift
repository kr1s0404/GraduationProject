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
                            .toolbar {
                                ToolbarItem(placement: .navigationBarLeading) {
                                    Button("超解析度還原") { superResolutionVM.makeImageSuperResolution(from: image) }
                                }
                            }
                        case .video( _):
                            Text("Can not select video")
                                .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showMediaPicker) { MediaPicker(media: $selectedMeida) }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("開啟相簿") { showMediaPicker.toggle() }
                }
            }
        }
    }
}

extension SuperResolutionView {
    
}

struct SuperResolutionView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SuperResolutionView()
    }
}
