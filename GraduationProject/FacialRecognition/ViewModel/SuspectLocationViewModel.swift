//
//  SuspectLocationViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit
import CoreLocation

@MainActor
final class SuspectLocationViewModel: ObservableObject
{
    @Published var fetchedSuspectData: [SuspectData]?
    @Published var suspectList = [Suspect]()
    @Published var defaultSuspect: Suspect? {
        didSet {
            guard let defaultSuspect = defaultSuspect else { return }
            updateMapRegion(suspect: defaultSuspect)
        }
    }
    
    @Published var region = MKCoordinateRegion()
    @Published var mapSpan = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
    @Published var userTrackingMode: MapUserTrackingMode = .follow
    
    @Published var showLocationList: Bool = false
    @Published var sheetSuspect: Suspect?
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
                                          imageURL: suspectData.imageURL,
                                          reason: suspectData.reason,
                                          agency: suspectData.agency)
            suspectList.append(Suspect(id: suspectData.id, suspectData: suspectData, uiImage: uiImage))
        }
        if let firstSuspect = suspectList.first {
            defaultSuspect = firstSuspect
            updateMapRegion(suspect: firstSuspect)
        }
        isLoading = false
    }
    
    private func suspectToLocation(suspect: Suspect) -> CLLocationCoordinate2D {
        let latitude = suspect.suspectData.latitude
        let longitude = suspect.suspectData.longitude
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    private func updateMapRegion(suspect: Suspect) {
        let location = suspectToLocation(suspect: suspect)
        DispatchQueue.main.async {
            withAnimation(.default) {
                self.region = MKCoordinateRegion(center: location, span: self.mapSpan)
            }
        }
    }
    
    public func toggleLocationList() {
        withAnimation(.easeInOut) {
            showLocationList.toggle()
        }
    }
    
    public func showNextLocation(suspect: Suspect) {
        DispatchQueue.main.async {
            withAnimation(.easeInOut) {
                self.defaultSuspect = suspect
                self.showLocationList = false
            }
        }
    }
    
    public func goToNextSusecpt() {
        guard let defaultSuspect = defaultSuspect,
              let currentIndex = suspectList.firstIndex(of: defaultSuspect)
        else { return }
        
        let nextIndex = currentIndex + 1
        guard suspectList.indices.contains(nextIndex) else {
            guard let firstSuspect = suspectList.first else { return }
            showNextLocation(suspect: firstSuspect)
            return
        }
        
        let nextSuspect = suspectList[nextIndex]
        showNextLocation(suspect: nextSuspect)
    }
}
