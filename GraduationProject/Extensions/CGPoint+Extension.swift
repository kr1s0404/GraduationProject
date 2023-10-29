//
//  CGPoint+Extension.swift
//  PoseEstimation_CoreML
//
//  Created by Kris on 10/6/23.
//

import SwiftUI

extension CGPoint: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
    
    public static func == (lhs: CGPoint, rhs: CGPoint) -> Bool {
        return lhs.x == rhs.x && lhs.y == rhs.y
    }
    
    static func +(lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    
    static func /(lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        guard rhs != 0.0 else { return lhs }
        return CGPoint(x: lhs.x / rhs, y: lhs.y / rhs)
    }
}

extension CGPoint {
    func angle(with p1: CGPoint, and p2: CGPoint) -> CGFloat {
        let center = self
        let transformedP1 = CGPoint(x: p1.x - center.x, y: p1.y - center.y)
        let transformedP2 = CGPoint(x: p2.x - center.x, y: p2.y - center.y)
        
        let angleToP1 = atan2(transformedP1.y, transformedP1.x)
        let angleToP2 = atan2(transformedP2.y, transformedP2.x)
        
        return normaliseToInteriorAngle(with: angleToP2 - angleToP1)
    }
    
    func normaliseToInteriorAngle(with angle: CGFloat) -> CGFloat {
        var angle = angle
        if (angle < 0) { angle += (2*CGFloat.pi) }
        if (angle > CGFloat.pi) { angle = 2*CGFloat.pi - angle }
        return angle
    }
}

func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x - right.x, y: left.y - right.y)
}

extension CGPoint {
    /// Euclidean Distance
    static func distance(_ a: CGPoint, _ b: CGPoint) -> Double {
        return sqrt(Double((b.x - a.x) * (b.x - a.x) + (b.y - a.y) * (b.y - a.y)))
    }
}

extension CGRect {
    var diagonal: Double {
        return CGPoint.distance(CGPoint(x: minX, y: minY), CGPoint(x: maxX, y: maxY))
    }
}
