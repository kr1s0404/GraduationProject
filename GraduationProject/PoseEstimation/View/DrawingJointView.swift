//
//  DrawingJointView.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import SwiftUI

struct DrawingJointView: View
{
    var joints: [CGPoint]
    
    var body: some View
    {
        GeometryReader { geometry in
            ZStack
            {
                ForEach(0 ..< joints.count, id: \.self) { index in
                    let jointPosition = joints[index]
                    
                    Circle()
                        .fill(Color(PoseConstants.pointColors[index % PoseConstants.pointColors.count]))
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black, lineWidth: 1.4))
                        .position(jointPosition)
                    
//                    Text(PoseConstants.BodyPoint.labels[index % PoseConstants.pointColors.count])
//                        .foregroundColor(Color(PoseConstants.pointColors[index % PoseConstants.pointColors.count]))
//                        .font(.caption2)
//                        .position(x: jointPosition.x + labelOffset(for: index), y: jointPosition.y)
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
    
    func labelOffset(for index: Int) -> CGFloat {
        let leftPartsIndices: [Int] = [5, 6, 7, 11, 12, 13]
        let rightPartsIndices: [Int] = [2, 3, 4, 8, 9, 10]
        
        if leftPartsIndices.contains(index) {
            return 105
        } else if rightPartsIndices.contains(index) {
            return -105
        }
        return 0
    }
}
