//
//  CaptureViewModel.swift
//  drowsinessDetector
//
//  Created by Igor Silva on 21/06/23.
//

import SwiftUI
import AVFoundation

class CaptureViewModel: ObservableObject {
    @Published var capturedImage: NSImage?
    @Published var count = 0
    
}

struct CameraView: NSViewRepresentable {
    @ObservedObject var vm: CaptureViewModel
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: _vm)
    }
    
    func makeNSView(context: Context) -> CameraPreviewView {
        let captureView = CameraPreviewView()
        captureView.coordinator = context.coordinator
        captureView.setupCaptureSession()
        return captureView
    }
    
    func updateNSView(_ nsView: CameraPreviewView, context: Context) {
    }
    
    class Coordinator: NSObject, AVCapturePhotoCaptureDelegate {
        @ObservedObject var viewModel: CaptureViewModel
        
        init(viewModel: ObservedObject<CaptureViewModel>) {
            _viewModel = viewModel
        }
        
        func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
            if let imageData = photo.fileDataRepresentation(),
               let image = NSImage(data: imageData) {
                viewModel.capturedImage = image
            }
        }
        
    }
}
