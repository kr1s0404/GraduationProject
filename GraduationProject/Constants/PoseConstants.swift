//
//  PoseConstants.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import SwiftUI

struct PoseConstants
{
    enum BodyPoint: Int, CaseIterable {
        case top
        case neck
        case rightShoulder
        case rightElbow
        case rightWrist
        case leftShoulder
        case leftElbow
        case leftWrist
        case rightHip
        case rightKnee
        case rightAnkle
        case leftHip
        case leftKnee
        case leftAnkle
        
        static var labels: [String] {
            return [
                "Top",
                "Neck",
                "Right Shoulder",
                "Right Elbow",
                "Right Wrist",
                "Left Shoulder",
                "Left Elbow",
                "Left Wrist",
                "Right Hip",
                "Right Knee",
                "Right Ankle",
                "Left Hip",
                "Left Knee",
                "Left Ankle"
            ]
        }
    }
    
    static let connectedPoints: [(BodyPoint, BodyPoint)] = [
        (.top, .neck),
        (.neck, .rightShoulder),
        (.rightShoulder, .rightElbow),
        (.rightElbow, .rightWrist),
        (.neck, .rightHip),
        (.rightHip, .rightKnee),
        (.rightKnee, .rightAnkle),
        (.neck, .leftShoulder),
        (.leftShoulder, .leftElbow),
        (.leftElbow, .leftWrist),
        (.neck, .leftHip),
        (.leftHip, .leftKnee),
        (.leftKnee, .leftAnkle)
    ]
    
    static let jointLineColor = UIColor(red: 26.0/255.0, green: 187.0/255.0, blue: 229.0/255.0, alpha: 0.8)
    
    static let pointColors: [UIColor] = [
        .red, .green, .blue, .cyan, .yellow,
        .magenta, .orange, .purple, .brown, .black,
        .darkGray, .lightGray, .white, .gray
    ]
}
