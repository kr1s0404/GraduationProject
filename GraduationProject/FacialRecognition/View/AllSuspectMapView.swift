//
//  AllSuspectMapView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct AllSuspectMapView: View
{
    @ObservedObject var locationVM: SuspectLocationViewModel
    
    var body: some View
    {
        if locationVM.isLoading {
            ProgressView()
        } else {
            ZStack
            {
                mapLayer
                
                if let currentSuspect = locationVM.defaultSuspect {
                    let suspectData = currentSuspect.suspectData
                    VStack(spacing: 0)
                    {
                        suspectLabelView(for: suspectData)
                        
                        Spacer()
                        
                        suspectPreviewCard
                    }
                }
            }
            .sheet(item: $locationVM.sheetSuspect) { suspect in
                SuspectDetailView(locationVM: locationVM, suspect: suspect)
            }
        }
    }
}

extension AllSuspectMapView {
    private var mapLayer: some View {
        Map(coordinateRegion: $locationVM.region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $locationVM.userTrackingMode, annotationItems: locationVM.suspectList) { suspect in
            MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: suspect.suspectData.latitude, longitude: suspect.suspectData.longitude)) {
                SuspectMapAnnotation(suspect: suspect)
                    .scaleEffect(locationVM.defaultSuspect == suspect ? 1 : 0.7)
                    .shadow(radius: 10)
                    .onTapGesture {
                        locationVM.showNextLocation(suspect: suspect)
                    }
            }
        }
        .edgesIgnoringSafeArea(.top)
    }
    
    private var suspectPreviewCard: some View {
        ZStack
        {
            ForEach(locationVM.suspectList) { suspect in
                if locationVM.defaultSuspect == suspect {
                    SuspectPreviewView(locationVM: locationVM, suspect: suspect)
                        .shadow(color: .black.opacity(0.3), radius: 20)
                        .padding()
                        .transition(.asymmetric(insertion: .move(edge: .trailing),
                                                removal: .move(edge: .leading)))
                }
            }
        }
    }
    
    private func suspectLabelString(for suspectData: SuspectData) -> String {
        let name = suspectData.name
        let age = suspectData.age.description
        let sex = suspectData.sex ? "男" : "女"
        let label = name + ", " + age + ", " + sex
        
        return label
    }
    
    @ViewBuilder
    private func suspectLabelView(for suspectData: SuspectData) -> some View {
        VStack
        {
            Button {
                locationVM.toggleLocationList()
            } label: {
                Text(suspectLabelString(for: suspectData))
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.primary)
                    .frame(height: 55)
                    .frame(maxWidth: .infinity)
                    .animation(.none, value: suspectData)
                    .overlay(alignment: .leading) {
                        Image(systemName: "arrow.down")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
                            .rotationEffect(Angle(degrees: locationVM.showLocationList ? 180 : 0))
                    }
            }
            
            if locationVM.showLocationList {
                SuspectListView(locationVM: locationVM)
            }
        }
        .background(.thickMaterial)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.3), radius: 2, x: 0, y: 15)
        .padding()
    }
}
