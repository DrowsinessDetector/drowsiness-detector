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

class CameraPreviewView: NSView {
    private var captureSession: AVCaptureSession?
    var coordinator: CameraView.Coordinator?
    var timer: Timer?
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    func setupCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {
            print("No video capture device found")
            return
        }
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { _ in
            guard let photoOutput = self.captureSession?.outputs.first(where: { $0 is AVCapturePhotoOutput }) as? AVCapturePhotoOutput else {
                print("No photo output found")
                return
            }
            
            let settings = AVCapturePhotoSettings()
            photoOutput.capturePhoto(with: settings, delegate: self.coordinator!)
            self.coordinator?.viewModel.count += 1
        })
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession = AVCaptureSession()
            captureSession?.addInput(input)
            
            let photoOutput = AVCapturePhotoOutput()
            captureSession?.addOutput(photoOutput)
            
            captureSession?.startRunning()
        } catch {
            print("Error setting up capture session: \(error)")
        }
    }
    
}

struct ContentView: View {
    @StateObject private var vm = CaptureViewModel()
    
    var body: some View {
        VStack {
            Text("Camera Capture")
                .font(.title)
                .padding()
            
            CameraView(vm: vm)
                .frame(width: 0, height: 0)
            
            if let image = vm.capturedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(alignment: .topTrailing) {
                        Text("\(vm.count)")
                            .font(.system(size: 40))
                            .foregroundColor(.red)
                    }
            } else {
                Text("No Image Captured")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
