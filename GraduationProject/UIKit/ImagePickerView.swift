//
//  ImagePickerView.swift
//  CarbonCredit
//
//  Created by Kris on 11/23/21.
//

import SwiftUI
import AVFoundation

enum Media {
    case image(UIImage)
    case video(URL)
}

struct MediaPicker: UIViewControllerRepresentable
{
    @Binding var media: Media?
    
    private let controller = UIImagePickerController()
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
    {
        let parent: MediaPicker
        
        init(parent: MediaPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.media = .image(image)
            } else if let videoUrl = info[.mediaURL] as? URL {
                parent.media = .video(videoUrl)
            }
            picker.dismiss(animated: true)
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            picker.dismiss(animated: true)
        }
    }
    
    func makeUIViewController(context: Context) -> some UIViewController {
        controller.delegate = context.coordinator
        controller.mediaTypes = ["public.image", "public.movie"]
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}
