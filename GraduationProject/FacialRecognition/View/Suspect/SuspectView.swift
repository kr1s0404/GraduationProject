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
                    ZStack
                    {
                        KFImage(URL(string: suspect.imageURL))
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                faceDetectionVM.selectedSuspect = suspect
                                faceDetectionVM.suspectImage = faceDetectionVM.detectSuspectImage()
                                faceDetectionVM.predictSuspectImage()
                            }
                        
                        if let suspectImage = faceDetectionVM.suspectImage {
                            if suspect.id == suspectImage.id {
                                Image(uiImage: suspectImage.uiImage)
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                    }
                }
            }
            .overlay { if faceDetectionVM.isLoading { ProgressView() } }
            .toolbar{
                fetchImageButton
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
                        guard let uiImage = await faceDetectionVM.fetchImage(from: imageURL) else { continue }
                        faceDetectionVM.suspectImageList.append(SuspectImage(id: UUID(), uiImage: uiImage, imageURL: imageURL))
                    }
                    faceDetectionVM.isLoading = false
                }
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
