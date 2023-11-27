//
//  SuspectMapView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit
import CoreLocation

struct SuspectMapView: View
{
    @State var region = MKCoordinateRegion()
    @State var userTrackingMode: MapUserTrackingMode = .follow
    
    @State var suspect: Suspect
    
    init(suspect: Suspect) {
        self._suspect = State(wrappedValue: suspect)
    }
    
    var body: some View
    {
        Map(coordinateRegion: $region, interactionModes: .all, showsUserLocation: true, userTrackingMode: $userTrackingMode, annotationItems: [suspect]) { suspect in
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
            let coordinate = CLLocationCoordinate2D(latitude: suspect.suspectData.latitude, longitude: suspect.suspectData.longitude)
            region.center = coordinate
            region.span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        }
    }
}
