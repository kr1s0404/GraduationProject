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
    
    public var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
    private var FaceNetModel: FacialDetectionModel_?
    
    private var suspectPictureBufferArray = Array(repeating: 0.0, count: 160*160*3)
    private var currentPictureBufferArray = Array(repeating: 0.0, count: 160*160*3)
    
    private var suspectInputArray = try? MLMultiArray(shape: Constants.pixelBufferDimensions, dataType: .float32)
    private var currentInputArray = try? MLMultiArray(shape: Constants.pixelBufferDimensions, dataType: .float32)
    
    enum Constants {
        static let pixelBufferDimensions: [NSNumber] = [1, 160, 160, 3]
    }
    
    override init() {
        super.init()
        Task {
            await setupSession()
            setupModel()
        }
    }
    
    private func setupSession() async {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        photoOutput = AVCapturePhotoOutput()
        
        do {
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
                  let videoInput = try? AVCaptureDeviceInput(device: videoCaptureDevice),
                  captureSession?.canAddInput(videoInput) == true
            else { throw FaceDetectionError.videoOutputInitializationFailed("Photo output failed") }
            
            captureSession?.addInput(videoInput)
            
            if let videoOutput = videoOutput, captureSession?.canAddOutput(videoOutput) == true {
                videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
                videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
                videoOutput.alwaysDiscardsLateVideoFrames = true
                captureSession?.addOutput(videoOutput)
            } else { throw FaceDetectionError.videoOutputInitializationFailed("Video output failed") }
            
            if let photoOutput = photoOutput, captureSession?.canAddOutput(photoOutput) == true {
                captureSession?.addOutput(photoOutput)
            } else { throw FaceDetectionError.photoOutputInitializationFailed("Photo output failed") }
            
            videoOutput?.connection(with: AVMediaType.video)?.videoOrientation = .portrait
        } catch {
            self.handleError(FaceDetectionError.cameraInputInitializationFailed(error.localizedDescription))
        }
    }
    
    private func setupModel() {
        do {
            FaceNetModel = try FacialDetectionModel_(configuration: .init())
        } catch {
            self.handleError(FaceDetectionError.modelSetupFailed(error.localizedDescription))
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
            guard let uiImage = UIImage(data: data) else { return }
            self.selectedImage = uiImage
        } catch {
            self.handleError(FaceDetectionError.imageFetchFailed(error.localizedDescription))
        }
    }
    
    private func cropImageByBoundingBox(inputImage: UIImage) async -> UIImage? {
        guard let ciImage = CIImage(image: inputImage) else { return nil }
        
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        
        do {
            try handler.perform([faceDetectionRequest])
            guard let results = faceDetectionRequest.results, let result = results.first else { return nil }
            let boundingBox = convertBoundingBox(result.boundingBox, to: inputImage.size)
            guard let croppedImage = cropAndResizeImage(inputImage, toBoundingBox: boundingBox, toTargetSize: CGSize(width: 160, height: 160)) else { return nil }
            
            return croppedImage
        } catch {
            self.handleError(FaceDetectionError.imageProcessingFailed(error.localizedDescription))
        }
        
        return nil
    }
    
    // Crop the given UIImage to the given bounding box and resize it to the target size
    private func cropAndResizeImage(_ image: UIImage,
                            toBoundingBox boundingBox: CGRect?,
                            toTargetSize targetSize: CGSize) -> UIImage? {
        guard let boundingBox = boundingBox else { return nil }
        
        // Make sure the rect is within the image bounds
        let imageRect = CGRect(origin: .zero, size: image.size)
        guard imageRect.contains(boundingBox) else { return nil }
        
        // Crop to the bounding box
        guard let cgImage = image.cgImage?.cropping(to: boundingBox) else { return nil }
        
        // Resize the cropped area
        let croppedUIImage = UIImage(cgImage: cgImage)
        return croppedUIImage.resized(to: targetSize)
    }
    
    private func drawBoudingBox(in pixelBuffer: CVPixelBuffer) {
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer,
                                                        orientation: .up,
                                                        options: [:])
        
        do {
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            try imageRequestHandler.perform([faceDetectionRequest])
            if let results = faceDetectionRequest.results {
                DispatchQueue.main.async { [weak self] in
                    self?.currentFaceData = results.map { FaceData(boundingBox: $0.boundingBox) }
                }
            }
        } catch {
            self.handleError(FaceDetectionError.imageProcessingFailed(error.localizedDescription))
        }
    }
    
    public func convertBoundingBox(_ box: CGRect, to targetSize: CGSize) -> CGRect {
        let scaleX = targetSize.width
        let scaleY = targetSize.height
        let x = (1 - box.origin.x - box.width) * scaleX // Inverting X-axis for SwiftUI
        let y = (1 - box.origin.y - box.height) * scaleY // Inverting Y-axis for SwiftUI
        let width = box.width * scaleX
        let height = box.height * scaleY
        
        return CGRect(x: x, y: y, width: width, height: height)
    }
    
    @MainActor
    func detectSuspectImage() {
        guard let selectedImage = selectedImage else { return }
        guard let imageBuffer = selectedImage.convertToBuffer() else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer, orientation: .up, options: [:])
        
        do {
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            try imageRequestHandler.perform([faceDetectionRequest])
            if let results = faceDetectionRequest.results {
                Task {
                    let croppedImage = await cropImageByBoundingBox(inputImage: selectedImage)
                    guard let image = croppedImage else { return }
                    self.recognizeSuspectImage(image: image)
                    self.suspectFaceData = results.first.map { FaceData(boundingBox: $0.boundingBox) }
                }
            }
        } catch {
            self.handleError(FaceDetectionError.faceDetectionFailed(error.localizedDescription))
        }
    }
    
    func recognizeSuspectImage(image: UIImage) {
        image.getPixelData(buffer: &self.suspectPictureBufferArray)
        image.prewhiten(input: &self.suspectPictureBufferArray, output: &self.suspectInputArray!)
        
        if let prediction = try? self.FaceNetModel?.prediction(input: self.suspectInputArray!) {
            self.suspectFaceMLMultiArray = prediction.embeddings
        }
        else {
            self.handleError(FaceDetectionError.modelPredictionFailed)
        }
    }
    
    func recognizeCurrentImage(image: UIImage) {
        image.getPixelData(buffer: &self.currentPictureBufferArray)
        image.prewhiten(input: &self.currentPictureBufferArray, output: &self.currentInputArray!)
        
        if let prediction = try? self.FaceNetModel?.prediction(input: self.currentInputArray!) {
            self.currentFaceMLMultiArray = prediction.embeddings
        }
        else {
            self.handleError(FaceDetectionError.modelPredictionFailed)
        }
    }
    
    private func cosineSimilarity(between vectorA: MLMultiArray, and vectorB: MLMultiArray) -> Double {
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
    
    private func compareFacialFeature() {
        guard let currentVector = currentFaceMLMultiArray,
              let suspectVector = suspectFaceMLMultiArray
        else { return }
        
        DispatchQueue.main.async {
            self.possibilty = self.cosineSimilarity(between: currentVector, and: suspectVector)
        }
    }
    
    private func handleError(_ error: FaceDetectionError) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.showAlert.toggle()
        }
    }
}

extension FaceDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    @MainActor
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let uiImage = UIImage(cgImage: cgImage)
        
        Task {
            let croppedImage = await cropImageByBoundingBox(inputImage: uiImage)
            guard let image = croppedImage else { return }
            self.recognizeCurrentImage(image: image)
            self.drawBoudingBox(in: pixelBuffer)
            self.compareFacialFeature()
        }
    }
}

extension FaceDetectionViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            handleError(FaceDetectionError.photoOutputInitializationFailed(error.localizedDescription))
            return
        }
        
        if let imageData = photo.fileDataRepresentation(), let image = UIImage(data: imageData) {
            DispatchQueue.main.async {
                self.capturedImage = image
            }
        }
    }
    
    public func captureFace() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
    }
}
