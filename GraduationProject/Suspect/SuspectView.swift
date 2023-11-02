//
//  SuspectView.swift
//  GraduationProject
//
//  Created by Kris on 11/2/23.
//

import SwiftUI
import Vision

struct SuspectView: View {
    @ObservedObject var suspectVM: SuspectViewModel
    @ObservedObject var firestoreVM: FirestoreViewModel
    
    @State var fetchedData: [ImageData]?
    @State var faceData: FaceData? // To store detected face data
    
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                Button("Fetch") {
                    Task {
                        self.fetchedData = await firestoreVM.fetchDocuments(from: Collection.Images,
                                                                            as: ImageData.self)
                    }
                }
                .padding()
                
                if let image = suspectVM.selectImage {
                    ZStack {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: image.size.width, height: image.size.height)
                            .scaledToFit()
                        
                        // Overlay for drawing bounding box and landmarks
                        if let faceData = faceData {
                            FaceOverlayView(faceData: faceData, imageSize: image.size)
                                .frame(width: image.size.width, height: image.size.height)
                        }
                    }
                }
                
                Button("Convert and Detect") {
                    Task {
                        await convertAndDetectImage()
                    }
                }
                .padding()
            }
            .alert(firestoreVM.errorMessage,
                   isPresented: $firestoreVM.showAlert,
                   actions: { Text("OK") })
        }
    }
    
    @MainActor
    private func convertAndDetectImage() async {
        guard let firstImageData = fetchedData?.first else { return }
        let imageUrlString = firstImageData.imageURL
        guard let imageURL = URL(string: imageUrlString)  else { return }
        
        let urlSession = URLSession.shared
        let urlRequest = URLRequest(url: imageURL)
        
        do {
            let (data, response) = try await urlSession.data(for: urlRequest)
            
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                let image = UIImage(data: data)
                suspectVM.selectImage = image
                
                // Detect facial landmarks
                if let image = image, let pixelBuffer = image.convertToBuffer() {
                    faceData = detectFaces(in: pixelBuffer)
                }
            } else {
                print("Invalid response or status code")
            }
        } catch {
            print("Error fetching image: \(error)")
        }
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

struct SelectSuspectView_Previews: PreviewProvider
{
    static var previews: some View
    {
        SuspectView(suspectVM: SuspectViewModel(),
                    firestoreVM: FirestoreViewModel())
    }
}

struct FaceOverlayView: View {
    let faceData: FaceData
    let imageSize: CGSize
    
    var body: some View {
        GeometryReader { geometry in
            let convertedBox = convertBoundingBox(faceData.boundingBox, to: imageSize)
            
            Rectangle()
                .stroke(Color.red, lineWidth: 2)
                .frame(width: convertedBox.width, height: convertedBox.height)
                .offset(x: convertedBox.minX, y: convertedBox.minY)
            
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
            }
        }
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
}
