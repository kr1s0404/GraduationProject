//
//  CameraView+Modifier.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI

struct CameraSafeAreaModifier: ViewModifier
{
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom, alignment: .center) {
                Color.clear
                    .frame(height: 0)
                    .background(Material.bar)
            }
            .ignoresSafeArea(.all, edges: .top)
    }
}

extension View {
    func cameraSafeArea() -> some View {
        modifier(CameraSafeAreaModifier())
    }
}

