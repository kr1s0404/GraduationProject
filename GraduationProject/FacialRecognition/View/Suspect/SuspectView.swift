//
//  SuspectView.swift
//  GraduationProject
//
//  Created by Kris on 11/2/23.
//

import SwiftUI
import Vision

struct SuspectView: View
{
    @ObservedObject var faceDetectionVM: FaceDetectionViewModel
    @ObservedObject var firestoreVM: FirestoreViewModel
    
    var body: some View
    {
        VStack
        {
            Button("Fetch") {
                Task {
                    faceDetectionVM.fetchedSuspectImageData = await firestoreVM.fetchDocuments(from: Collection.Images,
                                                                                               as: ImageData.self)
                    guard let firstImageData = faceDetectionVM.fetchedSuspectImageData?.first else { return }
                    await faceDetectionVM.convertDataToImage(frome: firstImageData.imageURL)
                }
            }
            .padding()
            
            if let image = faceDetectionVM.selectedImage {
                ZStack {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: image.size.width, height: image.size.height)
                        .scaledToFit()
                    
                    if let detectedSuspectFaceData = faceDetectionVM.suspectFaceData {
                        FaceOverlayView(faceData: detectedSuspectFaceData, imageSize: image.size)
                            .frame(width: image.size.width, height: image.size.height)
                    }
                }
            }
            
            Button("Detect") {
                faceDetectionVM.detectSuspectImage()
            }
            .padding()
        }
        .alert(firestoreVM.errorMessage,
               isPresented: $firestoreVM.showAlert,
               actions: { Text("OK") })
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
