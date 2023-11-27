//
//  SuspectPreviewView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI

struct SuspectPreviewView: View
{
    @ObservedObject var locationVM: SuspectLocationViewModel
    
    let suspect: Suspect
    
    var body: some View
    {
        let suspectData = suspect.suspectData
        
        HStack(alignment: .bottom, spacing: 0)
        {
            VStack(alignment: .leading, spacing: 16)
            {
                imageSection(suspect)
                titleSection(suspectData)
            }
            
            VStack(spacing: 8)
            {
                moreButton
                nextButton
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 10)
                .fill(.ultraThinMaterial)
                .offset(y: 65)
        }
        .cornerRadius(10)
        .clipped()
    }
}

extension SuspectPreviewView {
    @ViewBuilder
    private func imageSection(_ suspect: Suspect) -> some View {
        ZStack
        {
            Image(uiImage: suspect.uiImage)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
        }
        .padding(6)
        .background(.white)
        .cornerRadius(10)
    }
    
    @ViewBuilder
    private func titleSection(_ suspectData: SuspectData) -> some View {
        VStack(alignment: .leading)
        {
            
            Text(suspectData.name)
                .font(.title2)
                .bold()
            HStack
            {
                Text("\(suspectData.age), ")
                Text(suspectData.sex ? "男" : "女")
            }
            .font(.subheadline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var moreButton: some View {
        Button {
            
        } label: {
            Text("查看更多資料")
                .font(.headline)
                .frame(width: 125, height: 35)
        }
        .buttonStyle(.borderedProminent)
    }
    
    private var nextButton: some View {
        Button {
            locationVM.goToNextSusecpt()
        } label: {
            Text("下一位")
                .font(.headline)
                .frame(width: 125, height: 35)
        }
        .buttonStyle(.bordered)
    }
}
