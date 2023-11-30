//
//  LocationManager.swift
//  GraduationProject
//
//  Created by Kris on 11/30/23.
//

import SwiftUI
import CoreLocation
import Firebase

final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate
{
    @Published var location: CLLocationCoordinate2D?
    
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    
    override private init() {
        super.init()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locValue: CLLocationCoordinate2D = manager.location?.coordinate else { return }
        location = locValue
    }
}
