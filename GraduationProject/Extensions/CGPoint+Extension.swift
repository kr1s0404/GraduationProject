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
