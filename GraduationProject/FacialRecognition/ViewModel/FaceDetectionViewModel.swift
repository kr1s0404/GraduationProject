//
//  FaceDetectionViewModel.swift
//  GraduationProject
//
//  Created by Kris on 11/1/23.
//

import SwiftUI
import Vision
import AVFoundation

final class FaceDetectionViewModel: NSObject, ObservableObject
{
    @Published var currentFaceData: [FaceData] = []
    @Published var suspectFaceData: FaceData?
    @Published var currentFaceMLMultiArray: MLMultiArray?
    @Published var suspectFaceMLMultiArray: MLMultiArray?
    @Published var capturedImage: UIImage?
    @Published var possibilty: Double = 0.0
    
    @Published var selectedImage: UIImage?
    @Published var fetchedSuspectImageData: [ImageData]?
    
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private let faceLandmarksRequest = VNDetectFaceLandmarksRequest()
    
    private var faceNetModel: VNCoreMLModel?
    
    override init() {
        super.init()
        setupSession()
        setupModel()
    }
    
    func setupSession() {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        photoOutput = AVCapturePhotoOutput()
        
        do {
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  captureSession?.canAddInput(videoInput) == true else {
                throw NSError(domain: "FaceCameraViewModel", code: 1, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize camera input."])
            }
            
            captureSession?.addInput(videoInput)
            
            if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                videoOutput.alwaysDiscardsLateVideoFrames = true
                captureSession?.addOutput(videoOutput)
            } else {
                throw NSError(domain: "FaceCameraViewModel", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize video output."])
            }
            
            if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            } else {
                throw NSError(domain: "FaceCameraViewModel", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to initialize photo output."])
            }
            
            videoOutput?.connection(with: AVMediaType.video)?.videoOrientation = .portrait
            
        } catch {
            handleError(error.localizedDescription)
        }
    }
    
    private func setupModel() {
        do {
            let facialDetectionModel = try FacialDetectionModel_(configuration: .init())
            faceNetModel = try VNCoreMLModel(for: facialDetectionModel.model)
        } catch {
            handleError("Error setting up the model: \(error.localizedDescription)")
        }
    }
    
    func detectFaces(in pixelBuffer: CVPixelBuffer, completion: @escaping (MLMultiArray?) -> Void) {
        guard let model = faceNetModel else {
            self.handleError("CoreML model is not configured properly.")
            return
        }
        
        let request = VNCoreMLRequest(model: model) { request, error in
            if let error = error {
                self.handleError("Error: Face detection failed - \(error.localizedDescription)")
                completion(nil)
            } else {
                if let firstResult = request.results?.first as? VNCoreMLFeatureValueObservation,
                   let multiArray = firstResult.featureValue.multiArrayValue {
                    completion(multiArray)
                } else {
                    completion(nil)
                }
            }
        }
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        do {
            try handler.perform([request])
        } catch {
            handleError("Failed to perform detection: \(error.localizedDescription)")
            completion(nil)
        }
    }

    
    func drawBoudingBox(in pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results {
                DispatchQueue.main.async { [weak self] in
                    self?.currentFaceData = results.map { FaceData(boundingBox: $0.boundingBox) }
                }
            }
        } catch {
            self.handleError("Error: Face landmarks detection failed - \(error.localizedDescription)")
        }
    }
    
    func captureFace() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
    
    func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - box.origin.x - box.width) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - box.origin.y - box.height) * scaleY // Inverting Y-axis for SwiftUI
        let width = box.width * scaleX
        let height = box.height * scaleY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }

    func cosineSimilarity(between vectorA: MLMultiArray, and vectorB: MLMultiArray) -> Double {
        // Ensure the MLMultiArray is 1-D and both vectors have the same length
        guard vectorA.shape.count == 1, vectorB.shape.count == 1,
              vectorA.count == vectorB.count else { return 0.0 }
        
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
    
    func compareFaces() {
        guard let currentVector = currentFaceMLMultiArray,
              let suspectVector = suspectFaceMLMultiArray
        else { return }
        
        DispatchQueue.main.async {
            self.possibilty = self.cosineSimilarity(between: currentVector, and: suspectVector) * 100
        }
    }
    
    @MainActor
    func convertDataToImage(frome urlString: String) async {
        guard let imageURL = URL(string: urlString) else { return }
        let session = URLSession.shared
        let request = URLRequest(url: imageURL)
        
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else { return }
            guard let image = UIImage(data: data) else { return }
            selectedImage = image
        } catch {
            print("Error fetching image: \(error)")
        }
    }
    
    func detectImage() {
        guard let imageBuffer = selectedImage?.convertToBuffer() else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
            if let results = faceLandmarksRequest.results {
                DispatchQueue.main.async { [weak self] in
                    self?.detectFaces(in: imageBuffer) { array in
                        self?.suspectFaceMLMultiArray = array
                    }
                    self?.suspectFaceData = results.first.map { FaceData(boundingBox: $0.boundingBox) }
                }
            }
        } catch {
            self.handleError("Error: Face landmarks detection failed - \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ errorMessage: String) {
        self.errorMessage = "\(errorMessage)"
        showAlert.toggle()
    }
}


extension FaceDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        DispatchQueue.main.async {
            self.detectFaces(in: pixelBuffer) { result in
                self.currentFaceMLMultiArray = result
                self.drawBoudingBox(in: pixelBuffer)
                self.compareFaces()
            }
        }
    }
}

extension FaceDetectionViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            handleError(error.localizedDescription)
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
}
