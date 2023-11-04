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
    @ObservedObject var suspectVM: SuspectViewModel
    @ObservedObject var firestoreVM: FirestoreViewModel
    
    var body: some View
    {
        GeometryReader { geometry in
            VStack
            {
                Button("Fetch") {
                    Task {
                        suspectVM.fetchedData = await firestoreVM.fetchDocuments(from: Collection.Images,
                                                                                 as: ImageData.self)
                    }
                }
                .padding()
                
                if let image = suspectVM.selectedImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: image.size.width, height: image.size.height)
                            .scaledToFit()
                        
                        if let detectedFaceData = suspectVM.detectedFaceData {
                            FaceOverlayView(faceData: detectedFaceData, imageSize: image.size)
                                .frame(width: image.size.width, height: image.size.height)
                        }
                    }
                }
                
                Button("Convert and Detect") {
                    Task {
                        if let firstImageData = suspectVM.fetchedData?.first {
                            await suspectVM.convertAndDetectImage(from: firstImageData.imageURL)
                        }
                    }
                }
                .padding()
            }
            .alert(firestoreVM.errorMessage,
                   isPresented: $firestoreVM.showAlert,
                   actions: { Text("OK") })
        }
    }
}

struct SelectSuspectView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SuspectView(suspectVM: SuspectViewModel(),
                    firestoreVM: FirestoreViewModel())
    }
}
