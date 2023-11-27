//
//  SuspectPulseView.swift
//  GraduationProject
//
//  Created by Kris on 11/27/23.
//

import SwiftUI

struct SuspectPulseView: View
{
    @State var animate: Bool = false
    
    var body: some View
    {
        ZStack
        {
            Circle()
                .fill(Color.red.opacity(0.25))
                .frame(width: 130, height: 130)
                .scaleEffect(animate ? 1 : 0)
            
            Circle()
                .fill(Color.red.opacity(0.35))
                .frame(width: 100, height: 100)
                .scaleEffect(animate ? 1 : 0)
            
            Circle()
                .fill(Color.red.opacity(0.45))
                .frame(width: 70, height: 70)
                .scaleEffect(animate ? 1 : 0)
        }
        .onAppear { animate.toggle() }
        .onDisappear { animate.toggle() }
        .animation(.linear(duration: 3).repeatForever(autoreverses: false), value: animate)
    }
}
