//
//  FaceDetectionView.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import CoreVideo

struct FaceDetectionView: View
{
    @StateObject private var faceDetectionVM = FaceDetectionViewModel()
    @ObservedObject var suspectVM: SuspectViewModel
    
    @State var possibilty: Double = 0.0
    
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    
    var body: some View
    {
        NavigationStack
        {
            GeometryReader { geometry in
                ZStack(alignment: .bottom)
                {
                    CameraUIViewRepresentable(captureSession: faceDetectionVM.captureSession)
                        .ignoresSafeArea()
                    
                    ForEach(faceDetectionVM.faces, id: \.boundingBox) { faceData in
                        GeometryReader { faceGeometry in
                            let convertedBox = convertBoundingBox(faceData.boundingBox, to: faceGeometry.size)
                            
                            VStack
                            {
                                Rectangle()
                                    .stroke(Color.red, lineWidth: 2)
                                    .frame(width: convertedBox.width, height: convertedBox.height)
                                    .offset(x: convertedBox.minX, y: convertedBox.minY)
                                    .padding(.bottom)
                                
                                Text("\(possibilty)")
                                    .foregroundColor(possibilty > 80 ? .green : .red)
                            }
                            
                            if let facePoint = faceData.landmarks?.allPoints?.normalizedPoints {
                                ForEach(facePoint, id: \.self) { point in
                                    let boundingBoxSize = CGSize(width: convertedBox.width, height: convertedBox.height)
                                    let convertedPoint = convertPoint(point, to: boundingBoxSize)
                                    Circle()
                                        .fill(Color.white)
                                        .frame(width: 3, height: 3)
                                        .offset(x: convertedPoint.x, y: convertedPoint.y)
                                }
                                .offset(x: convertedBox.minX, y: convertedBox.minY)
                                .onAppear {
                                    
                                    let normalizedPoints = normalizePoints(facePoint, in: faceData.boundingBox.size)
                                    let vector = normalizedPoints.flatMap({ [Double($0.x), Double($0.y)] })
                                    
                                    
                                    if let face2 = suspectVM.selectImage {
                                        if let imageToBuffer = face2.convertToBuffer() {
                                            if let dectedFace = detectFaces(in: imageToBuffer) {
                                                if let facePoint2 = dectedFace.landmarks?.allPoints?.normalizedPoints {
                                                    let normalizedPoints2 = normalizePoints(facePoint2, in: dectedFace.boundingBox.size)
                                                    let vector2 = normalizedPoints2.flatMap({ [Double($0.x), Double($0.y)] })
                                                    
                                                    self.possibilty = ((cosineSimilarity(vector, vector2) + 1) / 2) * 100
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Button {
                        faceDetectionVM.captureFace()
                    } label: {
                        Circle()
                            .foregroundColor(.white)
                            .frame(width: 50, height: 50)
                            .padding(.bottom, 5)
                    }
                }
                .alert(faceDetectionVM.errorMessage, isPresented: $faceDetectionVM.showAlert, actions: { Text("OK") })
            }
        }
    }
    
    func normalizePoints(_ points: [CGPoint], in imageSize: CGSize) -> [CGPoint] {
        return points.map { CGPoint(x: $0.x / imageSize.width, y: $0.y / imageSize.height) }
    }
    
    private func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - box.origin.x - box.width) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - box.origin.y - box.height) * scaleY // Inverting Y-axis for SwiftUI
        let width = box.width * scaleX
        let height = box.height * scaleY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    private func convertPoint(_ point: CGPoint, to targetSize: CGSize) -> CGPoint {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - point.x) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - point.y) * scaleY // Inverting Y-axis for SwiftUI
        
        return CGPoint(x: x, y: y)
    }
    
    // Euclidean Distance
    func euclideanDistance(_ a: [Double], _ b: [Double]) -> Double {
        return sqrt(zip(a, b).map { (x, y) in pow(x - y, 2) }.reduce(0, +))
    }

    // Cosine Similarity
    func cosineSimilarity(_ a: [Double], _ b: [Double]) -> Double {
        let dotProduct = zip(a, b).map(*).reduce(0, +)
        let aMagnitude = sqrt(a.map { pow($0, 2) }.reduce(0, +))
        let bMagnitude = sqrt(b.map { pow($0, 2) }.reduce(0, +))
        return dotProduct / (aMagnitude * bMagnitude)
    }

    // Manhattan Distance
    func manhattanDistance(_ a: [Double], _ b: [Double]) -> Double {
        return zip(a, b).map { abs($0.0 - $0.1) }.reduce(0, +)
    }

    func detectFaces(in pixelBuffer: CVPixelBuffer) -> FaceData? {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results {
                return results.first.map { FaceData(boundingBox: $0.boundingBox, landmarks: $0.landmarks) }
            }
        } catch {
            print("Error: Face landmarks detection failed - \(error.localizedDescription)")
        }
        
        return nil
    }
}
