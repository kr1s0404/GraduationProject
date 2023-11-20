//
//  SuspectView.swift
//  GraduationProject
//
//  Created by Kris on 11/2/23.
//

import SwiftUI
import Vision
import Kingfisher

struct SuspectView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    @ObservedObject var firestoreVM: FirestoreViewModel
    
    var body: some View
    {
        NavigationStack
        {
            VStack
            {
                List(faceDetectionVM.suspectImageList) { suspect in
                    let image = suspect.uiImage
                    
                    ZStack {
                        KFImage(URL(string: suspect.imageURL))
                            .resizable()
                            .frame(width: image.size.width, height: image.size.height)
                            .scaledToFit()
                            .padding()
                            .onTapGesture {
                                faceDetectionVM.selectedSuspect = suspect
                                faceDetectionVM.detectSuspectImage()
                            }
                        
                        if faceDetectionVM.selectedSuspect?.id == suspect.id {
                            if let detectedSuspectFaceData = faceDetectionVM.suspectFaceData {
                                withAnimation(.spring()) {
                                    FaceOverlayView(faceData: detectedSuspectFaceData, imageSize: image.size)
                                        .frame(width: image.size.width, height: image.size.height)
                                }
                            }
                        }
                    }
                }
            }
            .overlay { if faceDetectionVM.isLoading { ProgressView() } }
            .toolbar{
                fetchImageButton
                detectFaceButton
            }
            .alert(firestoreVM.errorMessage, isPresented: $firestoreVM.showAlert, actions: { Text("OK") })
        }
    }
}

extension SuspectView {
    @ToolbarContentBuilder
    private var fetchImageButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button("Fetch") {
                Task {
                    faceDetectionVM.isLoading = true
                    faceDetectionVM.fetchedSuspectImageData = await firestoreVM.fetchDocuments(from: Collection.Images, as: ImageData.self)
                    guard let suspectImageDataList = faceDetectionVM.fetchedSuspectImageData else { return }
                    for suspectImageData in suspectImageDataList {
                        let imageURL = suspectImageData.imageURL
                        guard let uiImage = await faceDetectionVM.convertDataToImage(frome: imageURL) else { continue }
                        faceDetectionVM.suspectImageList.append(SuspectImage(uiImage: uiImage, imageURL: imageURL))
                    }
                    faceDetectionVM.isLoading = false
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var detectFaceButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button("Detect") {
                faceDetectionVM.detectSuspectImage()
            }
        }
    }
}

struct SelectSuspectView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SuspectView(faceDetectionVM: FaceDetectionViewModel(),
                    firestoreVM: FirestoreViewModel())
    }
}
