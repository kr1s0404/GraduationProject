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
            .onAppear {
                guard let latitude = locationVM.defaultSuspect?.suspectData.latitude,
                      let longitude = locationVM.defaultSuspect?.suspectData.longitude
                else { return }
                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                locationVM.region.center = coordinate
                locationVM.region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
            }
        }
    }
}
