//
//  SuspectMapAnnotation.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI

struct SuspectMapAnnotation: View
{
    let suspect: Suspect
    
    var body: some View
    {
        VStack(spacing: 0)
        {
            Image(uiImage: suspect.uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .clipShape(Circle())
                .frame(width: 60, height: 60)
                .cornerRadius(30)
                .padding(6)
                .background(.blue)
                .clipShape(Circle())
            
            Image(systemName: "triangle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(.blue)
                .frame(width: 15, height: 15)
                .rotationEffect(Angle(degrees: 180))
                .offset(y: -3)
                .padding(.bottom, 30)
        }
        .background(SuspectPulseView())
    }
}
