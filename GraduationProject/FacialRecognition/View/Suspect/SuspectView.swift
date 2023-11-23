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
                List(faceDetectionVM.suspectList) { suspect in
                    ZStack
                    {
                        KFImage(URL(string: suspect.suspectData.imageURL))
                            .resizable()
                            .scaledToFit()
                            .onTapGesture {
                                faceDetectionVM.selectedSuspect = suspect.suspectData
                            }
                            .task(id: faceDetectionVM.selectedSuspect) {
                                faceDetectionVM.suspect = await faceDetectionVM.detectSuspect()
                                faceDetectionVM.predictSuspectImage()
                            }
                        
                        if let selectedSuspect = faceDetectionVM.suspect {
                            if suspect.id == selectedSuspect.id {
                                Image(uiImage: selectedSuspect.uiImage)
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
                    faceDetectionVM.suspectList = []
                    faceDetectionVM.fetchedSuspectData = await firestoreVM.fetchDocuments(from: Collection.Suspect, as: SuspectData.self)
                    guard let suspectDataList = faceDetectionVM.fetchedSuspectData else { return }
                    for suspectData in suspectDataList {
                        guard let uiImage = await faceDetectionVM.fetchImage(from: suspectData.imageURL) else { continue }
                        let suspectData = SuspectData(id: UUID().uuidString,
                                                  name: suspectData.name,
                                                  age: suspectData.age,
                                                  sex: suspectData.sex,
                                                  latitude: suspectData.latitude,
                                                  longitude: suspectData.longitude,
                                                  imageURL: suspectData.imageURL)
                        faceDetectionVM.suspectList.append(Suspect(id: suspectData.id, suspectData: suspectData, uiImage: uiImage))
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
