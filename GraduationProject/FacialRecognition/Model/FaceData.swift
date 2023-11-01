//
//  FaceData.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import Foundation
import Vision

struct FaceData
{
    var boundingBox: CGRect
    var landmarks: VNFaceLandmarks2D?
    
    var leftEye: [CGPoint]? {
        landmarks?.leftEye?.normalizedPoints
    }
    
    var rightEye: [CGPoint]? {
        landmarks?.rightEye?.normalizedPoints
    }
}
