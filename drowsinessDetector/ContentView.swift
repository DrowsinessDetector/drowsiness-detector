import SwiftUI
import AVFoundation



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
    @State private var accuracy = 0.0
    @State private var isDrowsy = false
    var body: some View {
        VStack {
            CameraView(vm: vm)
                .frame(width: 0, height: 0)
                .onChange(of: vm.capturedImage) {
                    guard let image = $0 else { return }
                    let detector = try? DrowsinessDetector()
                    
                    if let (prediction, accuracy) = detector?.predict(image) {
                        print("Is drowsy ? \(String(describing: prediction)) \(accuracy)")
                        self.accuracy = accuracy
                        isDrowsy = (prediction ?? false)
                        if isDrowsy {
                            NSSound(named: "acorda")?.play()
                        }
                    }
                }
            
            if let image = vm.capturedImage {
                Image(nsImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .overlay(alignment: .topTrailing) {
                        Text("Quantidade de imagens capturadas: \(vm.count)")
                            .font(.system(size: 20))
                            .foregroundColor(.red)
                    }
                    .overlay(alignment: .bottomTrailing) {
                        HStack {
                            Text((isDrowsy ? "Cansado" : "Ativo"))
                                .font(.system(size: 40))
                                .foregroundColor(isDrowsy ? .red : .green)
                            if (accuracy > 0.60) && isDrowsy {
                                Text(String(format: "%.2f%%", accuracy * 100))
                                    .font(.system(size: 40))
                                    .foregroundColor(isDrowsy ? .red : .green)
                            }
                        }
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
