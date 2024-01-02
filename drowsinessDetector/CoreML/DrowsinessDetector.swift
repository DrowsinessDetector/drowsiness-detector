//
//  DrowsinessDetector.swift
//  drowsinessDetector
//
//  Created by Sérgio Ruediger on 20/06/23.
//

import AppKit

struct DrowsinessDetector {
    let model: CoreML
    
    init() throws {
        self.model = try CoreML(configuration: .init())
    }
    
    public func predict(_ image: NSImage) -> (Bool?, Double) {
        guard let imageData = self.preprocessData(from: image),
              let prediction = try? self.model.prediction(image: imageData)
        else { return (nil, 0.0) }
        let accuracy: Double = prediction.classLabelProbs["Fatigue Subjects"] ?? 0
        return (prediction.classLabel.contains("Fatigue"), accuracy)
    }
    
    private func preprocessData(from image: NSImage) -> CVPixelBuffer? {
        guard let data = image.tiffRepresentation,
              let ciImage = CIImage(data: data),
              let attributes = [String(kCVPixelBufferCGImageCompatibilityKey): true, String(kCVPixelBufferCGBitmapContextCompatibilityKey): true] as CFDictionary?
        else { return nil }
        
        let imageBounds: CGRect = ciImage.extent
        var pixelBuffer: CVPixelBuffer?
        
        CVPixelBufferCreate(kCFAllocatorDefault, Int(imageBounds.width), Int(imageBounds.height), kCVPixelFormatType_32ARGB, attributes, &pixelBuffer)
        
        if let pixelBuffer {
            let context = CIContext()
            context.render(ciImage, to: pixelBuffer)
            return pixelBuffer
        } else { return nil }
    }
}
