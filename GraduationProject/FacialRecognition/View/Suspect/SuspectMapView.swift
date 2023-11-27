//
//  SuspectMapView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit

struct SuspectMapView: View
{
    var suspect: Suspect
    
    init(suspect: Suspect) {
        self.suspect = suspect
    }
    
    var body: some View
    {
        VStack
        {
            Text(suspect.id)
        }
    }
}
