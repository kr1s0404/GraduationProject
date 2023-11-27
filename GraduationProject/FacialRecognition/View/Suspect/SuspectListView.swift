//
//  SuspectListView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI

struct SuspectListView: View
{
    @ObservedObject var locationVM: SuspectLocationViewModel
    
    var body: some View
    {
        List(locationVM.suspectList) { suspect in
            listRowView(suspect: suspect)
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
    }
}

extension SuspectListView {
    @ViewBuilder
    private func listRowView(suspect: Suspect) -> some View {
        HStack
        {
            Image(uiImage: suspect.uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .cornerRadius(10)
                .shadow(radius: 3)
            
            VStack(alignment: .leading)
            {
                Text(suspect.suspectData.name)
                    .font(.headline)
                HStack
                {
                    Text("\(suspect.suspectData.age)")
                    Text(suspect.suspectData.sex ? "男" : "女")
                }
                .font(.subheadline)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
