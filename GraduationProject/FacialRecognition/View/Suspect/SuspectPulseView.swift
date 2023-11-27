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
                .frame(width: 250, height: 250)
                .scaleEffect(animate ? 1 : 0)
            
            Circle()
                .fill(Color.red.opacity(0.35))
                .frame(width: 150, height: 150)
                .scaleEffect(animate ? 1 : 0)
            
            Circle()
                .fill(Color.red.opacity(0.45))
                .frame(width: 50, height: 50)
                .scaleEffect(animate ? 1 : 0)
        }
        .onAppear { animate.toggle() }
        .onDisappear { animate.toggle() }
        .animation(.linear(duration: 1.5).repeatForever(autoreverses: false), value: animate)
    }
}
