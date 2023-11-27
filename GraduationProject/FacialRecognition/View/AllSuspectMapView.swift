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
                Map(coordinateRegion: $locationVM.region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $locationVM.userTrackingMode, annotationItems: locationVM.suspectList) { suspect in
                    MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: suspect.suspectData.latitude, longitude: suspect.suspectData.longitude)) {
                        Image(uiImage: suspect.uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .cornerRadius(30)
                            .background(SuspectPulseView())
                    }
                }
                .ignoresSafeArea()
                
                if let currentSuspect = locationVM.defaultSuspect {
                    let suspectData = currentSuspect.suspectData
                    VStack(spacing: 0)
                    {
                        suspectLabelView(for: suspectData)
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

extension AllSuspectMapView {
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
                    .overlay(alignment: .leading) {
                        Image(systemName: "arrow.down")
                            .font(.headline)
                            .foregroundColor(.primary)
                            .padding()
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
