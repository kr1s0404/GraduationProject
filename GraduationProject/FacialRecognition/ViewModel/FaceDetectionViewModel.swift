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
    @Published var captureFaceMLMultiArray: MLMultiArray?
    @Published var capturedImage: UIImage?
    
    @Published var fetchedSuspectData: [SuspectData]?
    @Published var suspectList: [Suspect] = []
    
    @Published var showComparisonView: Bool = false
    @Published var isLoading: Bool = false
    @Published var showAlert: Bool = false
    @Published var errorMessage: String = ""
    
    public var captureSession: AVCaptureSession?
    private var videoOutput: AVCaptureVideoDataOutput?
    private var photoOutput: AVCapturePhotoOutput?
    private let faceDetectionRequest = VNDetectFaceRectanglesRequest()

    private var resNet50: ResNet50?
    
    private let firestoreService = FirestoreManager.shared
    private let metricsService = MetricsService()
    
    override init() {
        super.init()
        Task {
            await setupSession()
            await fetchSuspect()
            setupModel()
        }
    }
    
    private func setupSession() async {
        captureSession = AVCaptureSession()
        videoOutput = AVCaptureVideoDataOutput()
        photoOutput = AVCapturePhotoOutput()
        
        do {
            guard let videoCaptureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
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
            resNet50 = try ResNet50(configuration: .init())
        } catch {
            self.handleError(FaceDetectionError.modelSetupFailed(error.localizedDescription))
        }
    }
    
    @MainActor
    func fetchImage(from urlString: String) async -> UIImage? {
        do {
            guard let imageURL = URL(string: urlString) else { return nil }
            let (data, _) = try await URLSession.shared.data(from: imageURL)
            return UIImage(data: data)
        } catch {
            handleError(.imageFetchFailed(error.localizedDescription))
            return nil
        }
    }
    
    @MainActor
    func fetchSuspect() async {
        isLoading = true
        suspectList.removeAll()
        fetchedSuspectData = await firestoreService.fetchDocuments(from: Collection.Suspect, as: SuspectData.self)
        guard let suspectDataList = fetchedSuspectData else { return }
        for suspectData in suspectDataList {
            guard let uiImage = await fetchImage(from: suspectData.imageURL) else { continue }
            let suspectData = SuspectData(id: UUID().uuidString,
                                      name: suspectData.name,
                                      age: suspectData.age,
                                      sex: suspectData.sex,
                                      latitude: suspectData.latitude,
                                      longitude: suspectData.longitude,
                                      imageURL: suspectData.imageURL)
            suspectList.append(Suspect(id: suspectData.id, suspectData: suspectData, uiImage: uiImage))
        }
        isLoading = false
    }
    
    @MainActor
    func cropImageToFace(_ image: UIImage, boundingBox: CGRect) -> UIImage? {
        guard let cgImage = image.cgImage?.cropping(to: boundingBox) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    @MainActor
    func drawBoundingBox(boundingBox: CGRect, on data: Data) -> UIImage? {
        guard var uiImage = UIImage(data: data) else { return nil }
        let imageSize = uiImage.size
        
        let scaledBox = CGRect(x: boundingBox.origin.x * imageSize.width,
                               y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
                               width: boundingBox.size.width * imageSize.width,
                               height: boundingBox.size.height * imageSize.height)
        
        UIGraphicsBeginImageContext(imageSize)
        uiImage.draw(at: .zero)
        let drawingContext = UIGraphicsGetCurrentContext()!
        drawingContext.setStrokeColor(UIColor.red.cgColor)
        drawingContext.setLineWidth(8)
        drawingContext.stroke(scaledBox)
        uiImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        guard let croppedImage = cropImageToFace(uiImage, boundingBox: scaledBox)
        else { return nil }
        
        return croppedImage
    }
    
    @MainActor
    func predictAndSortSuspects() {
        guard let capturedImage = capturedImage,
              let cgImage = capturedImage.cgImage,
              let model = resNet50
        else { return }
        
        do {
            let captureResult = try model.prediction(input: ResNet50Input(imageWith: cgImage))
            self.captureFaceMLMultiArray = captureResult.output1
        } catch {
            print(error.localizedDescription)
            return
        }
        
        for index in 0..<suspectList.count {
            var suspect = suspectList[index]
            guard let suspectImage = detectSuspectFace(suspect.uiImage),
                  let captureFaceMLMultiArray = captureFaceMLMultiArray
            else { continue }
            
            if let croppedCGImage = suspectImage.cgImage {
                do {
                    let suspectResult = try model.prediction(input: ResNet50Input(imageWith: croppedCGImage))
                    let output = suspectResult.output1
                    suspect.faceMLMultiArray = output
                    suspect.detectedImage = suspectImage
                    
                    let euclideanDistance = metricsService.euclideanDistance(between: output, and: captureFaceMLMultiArray)
                    let cosineSimilarityValue = metricsService.cosineSimilarity(between: output, and: captureFaceMLMultiArray)
                    let similarityScore = metricsService.finalScoreForSimilarity(euclideanDistance: euclideanDistance, cosineSimilarity: cosineSimilarityValue)
                    suspect.score = similarityScore
                } catch {
                    print(error.localizedDescription)
                }
            }

            suspectList[index] = suspect
        }
        
        suspectList.sort { ($0.score ?? 0.0) > ($1.score ?? 0.0) }
    }
    
    @MainActor
    func detectSuspectFace(_ image: UIImage) -> UIImage? {
        let faceDetectionRequest = VNDetectFaceRectanglesRequest()
        guard let cgImage = image.cgImage else { return nil }
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        
        do {
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            try handler.perform([faceDetectionRequest])
            if let firstResult = faceDetectionRequest.results?.first {
                let imageSize = image.size
                let boundingBox = firstResult.boundingBox
                let scaledBox = CGRect(x: boundingBox.origin.x * imageSize.width,
                                       y: (1 - boundingBox.origin.y - boundingBox.size.height) * imageSize.height,
                                       width: boundingBox.size.width * imageSize.width,
                                       height: boundingBox.size.height * imageSize.height)
                
                let normalizedRect = VNNormalizedRectForImageRect(scaledBox, Int(imageSize.width), Int(imageSize.height))
                
                var suspectImage = image
                UIGraphicsBeginImageContext(imageSize)
                suspectImage.draw(at: .zero)
                let context = UIGraphicsGetCurrentContext()!
                context.setStrokeColor(UIColor.red.cgColor)
                context.setLineWidth(3)
                context.stroke(CGRect(x: normalizedRect.origin.x * imageSize.width,
                                      y: normalizedRect.origin.y * imageSize.height,
                                      width: normalizedRect.size.width * imageSize.width,
                                      height: normalizedRect.size.height * imageSize.height))
                suspectImage = UIGraphicsGetImageFromCurrentImageContext()!
                guard let croppedImage = self.cropImageToFace(suspectImage, boundingBox: scaledBox) else { return nil }
                suspectImage = croppedImage
                UIGraphicsEndImageContext()
                
                return suspectImage
            }
        } catch {
            print(error.localizedDescription)
        }
        
        return nil
    }
    
    private func handleError(_ error: FaceDetectionError) {
        DispatchQueue.main.async { [weak self] in
            self?.errorMessage = error.localizedDescription
            self?.showAlert.toggle()
        }
    }
}

extension FaceDetectionViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        
        guard let imageData = photo.fileDataRepresentation() else { return }
        let imageRequestHandler = VNImageRequestHandler(data: imageData)
        
        do {
            faceDetectionRequest.revision = VNDetectFaceRectanglesRequestRevision3
            try imageRequestHandler.perform([faceDetectionRequest])
            
            guard let results = faceDetectionRequest.results,
                  let firstResult = results.first
            else { return }
            
            let boundingBox = firstResult.boundingBox
            DispatchQueue.main.async {
                self.capturedImage = self.drawBoundingBox(boundingBox: boundingBox, on: imageData)
                self.predictAndSortSuspects()
            }
        } catch {
            self.handleError(FaceDetectionError.faceDetectionFailed(error.localizedDescription))
        }
    }
    
    public func captureFace() {
        let settings = AVCapturePhotoSettings()
        self.photoOutput?.capturePhoto(with: settings, delegate: self)
        self.showComparisonView.toggle()
    }
}

extension FaceDetectionViewModel: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
