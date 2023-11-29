//
//  SuspectDetailView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI
import MapKit

struct SuspectDetailView: View
{
    @ObservedObject var locationVM: SuspectLocationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State var isReport: Bool = false
    let suspect: Suspect
    
    var body: some View
    {
        ScrollView
        {
            VStack
            {
                suspectImage
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                
                VStack(alignment: .leading, spacing: 16)
                {
                    VStack(alignment: .leading, spacing: 8)
                    {
                        suspectTitle
                        Divider()
                        suspectDescription
                        Divider()
                        mapLayer
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            }
        }
        .ignoresSafeArea()
        .background(.ultraThinMaterial)
        .overlay(alignment: .topLeading) {
            backButton
        }
    }
}

extension SuspectDetailView {
    private var suspectImage: some View {
        TabView
        {
            Image(uiImage: suspect.uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: UIScreen.main.bounds.width)
                .clipped()
        }
        .frame(height: 500)
        .tabViewStyle(.page)
    }
    
    private var suspectTitle: some View {
        VStack(alignment: .leading, spacing: 8)
        {
            Text(suspect.suspectData.name)
                .font(.largeTitle)
                .fontWeight(.semibold)
            HStack
            {
                Text("\(suspect.suspectData.age), ")
                Text(suspect.suspectData.sex ? "男" : "女")
                Spacer()
                reportButton
            }
            .font(.title3)
            .foregroundColor(.secondary)
        }
    }
    
    private var suspectDescription: some View {
        VStack(alignment: .leading, spacing: 8)
        {
            Text("通緝事由：\(suspect.suspectData.reason)")
                .font(.headline)
                .foregroundColor(.primary)
            Text("通緝單位：\(suspect.suspectData.agency)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text("查看更多")
                .font(.callout)
                .foregroundColor(.blue)
        }
    }
    
    @ViewBuilder
    private var mapLayer: some View {
        let latitude = suspect.suspectData.latitude
        let longitude = suspect.suspectData.longitude
        let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        let span = MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        
        Map(coordinateRegion: .constant(MKCoordinateRegion(center: coordinate, span: span)), annotationItems: [suspect]) { suspect in
            MapAnnotation(coordinate: coordinate) {
                SuspectMapAnnotation(suspect: suspect)
                    .shadow(radius: 10)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .cornerRadius(30)
    }
    
    private var reportButton: some View {
        Button {
            withAnimation(.spring()) {
                isReport.toggle()
            }
        } label: {
            Text(isReport ? "定位中" : "即時通報, 定位追蹤")
                .font(.headline)
                .padding(16)
                .foregroundColor(.primary)
                .background(isReport ? .red : .green)
                .cornerRadius(10)
                .shadow(radius: 4)
        }
    }
    
    private var backButton: some View {
        Button {
            locationVM.sheetSuspect = nil
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.headline)
                .padding(16)
                .foregroundColor(.primary)
                .background(.thickMaterial)
                .cornerRadius(10)
                .shadow(radius: 4)
                .padding()
        }
    }
}
