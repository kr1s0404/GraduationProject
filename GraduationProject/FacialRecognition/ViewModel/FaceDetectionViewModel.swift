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
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()
    
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
    
    func preprocessImageForFaceNet(inputImage: UIImage, completion: @escaping (CVPixelBuffer?) -> Void) {
        // Convert the UIImage to a CIImage
        guard let ciImage = CIImage(image: inputImage) else {
            completion(nil)
            return
        }
        
        // Create a Vision request to detect faces
        let faceDetectionRequest = VNDetectFaceRectanglesRequest { [weak self] request, error in
            if let error = error {
                self?.handleError("Face detection error: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let results = request.results as? [VNFaceObservation], let result = results.first else {
                self?.handleError("No faces detected.")
                completion(nil)
                return
            }
            
            // Calculate the bounding box's size and position in terms of the original image size
            let boundingBox = self?.transformBoundingBox(result.boundingBox, toSize: inputImage.size)
            
            // Crop and resize the image
            if let croppedImage = self?.cropAndResizeImage(inputImage,
                                                           toBoundingBox: boundingBox,
                                                           toTargetSize: CGSize(width: 160, height: 160)) {
                // Convert the UIImage back to a CVPixelBuffer to pass to CoreML
                let pixelBuffer = croppedImage.convertToBuffer()
                completion(pixelBuffer)
            } else {
                completion(nil)
            }
        }
        
        // Perform the request using the Vision framework
        let handler = VNImageRequestHandler(ciImage: ciImage, options: [:])
        do {
            try handler.perform([faceDetectionRequest])
        } catch {
            handleError("Vision request failed with error: \(error.localizedDescription)")
            completion(nil)
        }
    }
    
    // Converts the bounding box to the coordinate system of the image
    func transformBoundingBox(_ boundingBox: CGRect, toSize imageSize: CGSize) -> CGRect {
        return CGRect(
            x: boundingBox.minX * imageSize.width,
            y: (1 - boundingBox.maxY) * imageSize.height, // Convert to correct coordinate system
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
    }
    
    // Crop the given UIImage to the given bounding box and resize it to the target size
    func cropAndResizeImage(_ image: UIImage,
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
        guard let selectedImage = selectedImage else { return }
        guard let imageBuffer = selectedImage.convertToBuffer() else { return }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: imageBuffer,
                                                        orientation: .up,
                                                        options: [:])
        
        do {
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            try imageRequestHandler.perform([faceDetectionRequest])
            if let results = faceDetectionRequest.results {
                preprocessImageForFaceNet(inputImage: selectedImage) { processedPixelBuffer in
                    guard let buffer = processedPixelBuffer else { return }
                    DispatchQueue.main.async {
                        self.detectFaces(in: buffer) { array in
                            self.suspectFaceMLMultiArray = array
                            self.suspectFaceData = results.first.map { FaceData(boundingBox: $0.boundingBox) }
                        }
                    }
                }
            }
        } catch {
            self.handleError("Error: Face landmarks detection failed - \(error.localizedDescription)")
        }
    }
    
    private func handleError(_ errorMessage: String) {
        DispatchQueue.main.async {
            self.errorMessage = "\(errorMessage)"
            self.showAlert.toggle()
        }
    }
}


extension FaceDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Convert pixel buffer to UIImage
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        let context = CIContext(options: nil)
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else { return }
        let image = UIImage(cgImage: cgImage)
        
        // Preprocess the image before feeding it to FaceNet
        preprocessImageForFaceNet(inputImage: image) { processedPixelBuffer in
            guard let buffer = processedPixelBuffer else { return }
            DispatchQueue.main.async {
                self.detectFaces(in: buffer) { array in
                    self.currentFaceMLMultiArray = array
                    self.drawBoudingBox(in: pixelBuffer)
                    self.compareFaces()
                }
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
