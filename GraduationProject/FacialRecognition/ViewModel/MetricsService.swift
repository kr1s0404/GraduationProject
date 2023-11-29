//
//  MetricsService.swift
//  GraduationProject
//
//  Created by Kris on 11/26/23.
//

import SwiftUI
import Vision

final class MetricsService
{
    func cosineSimilarity(between vectorA: MLMultiArray, and vectorB: MLMultiArray) -> Double {
        guard vectorA.count == vectorB.count else { return 0.0 }
        
        // Convert MLMultiArray to Swift arrays
        let arrayA = (0..<vectorA.count).map { Double(truncating: vectorA[$0]) }
        let arrayB = (0..<vectorB.count).map { Double(truncating: vectorB[$0]) }
        
        // Compute the cosine similarity between arrayA and arrayB
        let dotProduct = zip(arrayA, arrayB).map(*).reduce(0, +)
        let magnitudeA = sqrt(arrayA.map { $0 * $0 }.reduce(0, +))
        let magnitudeB = sqrt(arrayB.map { $0 * $0 }.reduce(0, +))
        
        // Check for non-zero magnitudes to avoid division by zero
        if magnitudeA != 0 && magnitudeB != 0 {
            return dotProduct / (magnitudeA * magnitudeB)
        } else { return 0.0 }
    }
    
    func euclideanDistance(between vectorA: MLMultiArray, and vectorB: MLMultiArray) -> Double {
        guard vectorA.count == vectorB.count else { return Double.infinity }

        // Convert MLMultiArray to Swift arrays
        let arrayA = (0..<vectorA.count).compactMap { Double(truncating: vectorA[$0]) }
        let arrayB = (0..<vectorB.count).compactMap { Double(truncating: vectorB[$0]) }

        // Compute the Euclidean distance between arrayA and arrayB
        let distance = zip(arrayA, arrayB).map { (a, b) -> Double in
            let difference = a - b
            return difference * difference
        }.reduce(0, +)

        return sqrt(distance)
    }
    
    private func normalizeEuclideanDistance(_ distance: Double, usingThreshold threshold: Double) -> Double {
        let normalized = min(distance / threshold, 1.0)
        print("distance: \(distance) \t normalized: \(normalized)")
        return 1.0 - normalized // Invert so that closer faces have higher scores
    }

    private func adjustedCosineSimilarity(_ similarity: Double) -> Double {
        return (similarity + 1.0) / 2.0 // Adjusting range from -1~1 to 0~1
    }
    
    private func combinedScore(euclidean: Double, cosine: Double) -> Double {
        let normalizedEuclidean = normalizeEuclideanDistance(euclidean, usingThreshold: 120)
        let adjustedCosine = adjustedCosineSimilarity(cosine)
        
        let euclideanWeight = normalizedEuclidean > 0.2 ? 1.0 : 3.0
        let cosineWeight = 3.0
        let totalWeight = euclideanWeight + cosineWeight
        
        let weightedEuclidean = normalizedEuclidean * euclideanWeight
        let weightedCosine = adjustedCosine * cosineWeight
        
        let weightedAverage = (weightedEuclidean + weightedCosine) / totalWeight
        
        print("\(normalizedEuclidean) \t \(adjustedCosine) \t \(weightedAverage) \t \n")
        return weightedAverage
    }

    func finalScoreForSimilarity(euclideanDistance: Double, cosineSimilarity: Double) -> Double {
        let combined = combinedScore(euclidean: euclideanDistance, cosine: cosineSimilarity)
        return combined * 100 // Scale to 0-100
    }
}
