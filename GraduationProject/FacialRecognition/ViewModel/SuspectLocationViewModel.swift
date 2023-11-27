//
//  SuspectLocationViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit

final class SuspectLocationViewModel: ObservableObject
{
    @Published var fetchedSuspectData: [SuspectData]?
    @Published var suspectList = [Suspect]()
    @Published var defaultSuspect: Suspect?
    
    @Published var region = MKCoordinateRegion()
    @Published var userTrackingMode: MapUserTrackingMode = .follow
    
    @Published var isLoading: Bool = false
    
    private let firestoreService = FirestoreManager.shared
    
    init() {
        Task {
            await fetchSuspect()
        }
    }
    
    @MainActor
    func fetchImage(from urlString: String) async -> UIImage? {
        do {
            guard let imageURL = URL(string: urlString) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            return UIImage(data: data)
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
    
    @MainActor
    func fetchSuspect() async {
        isLoading = true
        suspectList.removeAll()
        fetchedSuspectData = await firestoreService.fetchDocuments(from: Collection.Suspect, as: SuspectData.self)
        guard let suspectDataList = fetchedSuspectData else { return }
        for suspectData in suspectDataList {
            guard let uiImage = await fetchImage(from: suspectData.imageURL) else { continue }
            let suspectData = SuspectData(id: UUID().uuidString,
                                          name: suspectData.name,
                                          age: suspectData.age,
                                          sex: suspectData.sex,
                                          latitude: suspectData.latitude,
                                          longitude: suspectData.longitude,
                                          imageURL: suspectData.imageURL)
            suspectList.append(Suspect(id: suspectData.id, suspectData: suspectData, uiImage: uiImage))
        }
        defaultSuspect = suspectList.first
        isLoading = false
    }
}
