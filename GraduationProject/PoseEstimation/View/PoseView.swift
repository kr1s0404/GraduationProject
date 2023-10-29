//
//  PoseView.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/12/23.
//

import SwiftUI

struct PoseView: View
{
    var joints: [CGPoint]
    
    var body: some View
    {
        ZStack
        {
            ForEach(0 ..< joints.count, id: \.self) { index in
                let jointPosition = joints[index]
                
                Circle()
                    .fill(Color(PoseConstants.pointColors[index % PoseConstants.pointColors.count]))
                    .frame(width: 10, height: 10)
                    .overlay(Circle().stroke(Color.black, lineWidth: 1.4))
                    .position(jointPosition)
            }
            
            // Draw lines
            Path { path in
                for pair in PoseConstants.connectedPoints {
                    let p1Index = pair.0.rawValue
                    let p2Index = pair.1.rawValue
                    if p1Index < joints.count && p2Index < joints.count {
                        let p1 = joints[p1Index]
                        let p2 = joints[p2Index]
                        path.move(to: p1)
                        path.addLine(to: p2)
                    }
                }
            }
            .stroke(Color(PoseConstants.jointLineColor), lineWidth: 3)
        }
    }
}
