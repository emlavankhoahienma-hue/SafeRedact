import Foundation
import UIKit
import Vision

public final class PIIDetectionEngine {
    public static let shared = PIIDetectionEngine()
    
    private init() {}
    
    // Regular expressions for critical privacy patterns
    private let phoneRegex = try? NSRegularExpression(
        pattern: #"(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}"#,
        options: .caseInsensitive
    )
    
    private let emailRegex = try? NSRegularExpression(
        pattern: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#,
        options: .caseInsensitive
    )
    
    // 9-19 digits with optional spaces or dashes (Bank accounts, Vietnamese CCCD 12 digits, Credit/Debit cards)
    private let cardOrIdRegex = try? NSRegularExpression(
        pattern: #"\b(?:\d[ -]*?){9,19}\b"#,
        options: []
    )
    
    public func detectSensitiveData(in image: UIImage) async -> [DetectedRegion] {
        guard let cgImage = image.cgImage else { return [] }
        
        var regions: [DetectedRegion] = []
        
        // 1. Detect Text with VNRecognizeTextRequest
        let textRegions = await detectTextRegions(in: cgImage)
        regions.append(contentsOf: textRegions)
        
        // 2. Detect Faces with VNDetectFaceRectanglesRequest
        let faceRegions = await detectFaceRegions(in: cgImage)
        regions.append(contentsOf: faceRegions)
        
        // 3. Detect Barcodes & QR codes with VNDetectBarcodesRequest
        let barcodeRegions = await detectBarcodeRegions(in: cgImage)
        regions.append(contentsOf: barcodeRegions)
        
        return regions
    }
    
    // MARK: - Vision Text Recognition
    
    private func detectTextRegions(in cgImage: CGImage) async -> [DetectedRegion] {
        await withCheckedContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var detected: [DetectedRegion] = []
                
                for observation in observations {
                    guard let topCandidate = observation.topCandidates(1).first else { continue }
                    let string = topCandidate.string
                    
                    // Convert bounding box from Vision coordinates (origin bottom-left)
                    // to SwiftUI coordinates (origin top-left)
                    let visionBox = observation.boundingBox
                    let uiRect = CGRect(
                        x: visionBox.origin.x,
                        y: 1.0 - visionBox.origin.y - visionBox.height,
                        width: visionBox.width,
                        height: visionBox.height
                    )
                    
                    // Match against PII Patterns
                    if let type = self.classifyText(string) {
                        detected.append(
                            DetectedRegion(
                                type: type,
                                text: string,
                                normalizedRect: uiRect,
                                isRedacted: true
                            )
                        )
                    }
                }
                
                continuation.resume(returning: detected)
            }
            
            request.recognitionLevel = .accurate
            request.usesCPUOnly = false
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - Vision Face Detection
    
    private func detectFaceRegions(in cgImage: CGImage) async -> [DetectedRegion] {
        await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, error in
                guard error == nil, let observations = request.results as? [VNFaceObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var detected: [DetectedRegion] = []
                for face in observations {
                    let box = face.boundingBox
                    let uiRect = CGRect(
                        x: box.origin.x,
                        y: 1.0 - box.origin.y - box.height,
                        width: box.width,
                        height: box.height
                    )
                    detected.append(
                        DetectedRegion(
                            type: .face,
                            text: "Face",
                            normalizedRect: uiRect,
                            isRedacted: true
                        )
                    )
                }
                continuation.resume(returning: detected)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - Vision Barcode / QR Detection
    
    private func detectBarcodeRegions(in cgImage: CGImage) async -> [DetectedRegion] {
        await withCheckedContinuation { continuation in
            let request = VNDetectBarcodesRequest { request, error in
                guard error == nil, let observations = request.results as? [VNBarcodeObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var detected: [DetectedRegion] = []
                for barcode in observations {
                    let box = barcode.boundingBox
                    let uiRect = CGRect(
                        x: box.origin.x,
                        y: 1.0 - box.origin.y - box.height,
                        width: box.width,
                        height: box.height
                    )
                    let payload = barcode.payloadStringValue ?? "Barcode / QR"
                    detected.append(
                        DetectedRegion(
                            type: .barcode,
                            text: payload,
                            normalizedRect: uiRect,
                            isRedacted: true
                        )
                    )
                }
                continuation.resume(returning: detected)
            }
            
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(returning: [])
            }
        }
    }
    
    // MARK: - Pattern Classification
    
    public func classifyText(_ text: String) -> PIIType? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return nil }
        
        let range = NSRange(location: 0, length: trimmed.utf16.count)
        
        // 1. Email check
        if let emailRegex = emailRegex, emailRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            return .email
        }
        
        // 2. Phone check via Regex
        if let phoneRegex = phoneRegex, phoneRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            let digitsOnly = trimmed.filter { $0.isNumber }
            if digitsOnly.count >= 9 && digitsOnly.count <= 13 {
                return .phone
            }
        }
        
        // 3. Card / Account / Citizen ID check
        if let cardRegex = cardOrIdRegex, cardRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            let digitsOnly = trimmed.filter { $0.isNumber }
            if digitsOnly.count >= 9 && digitsOnly.count <= 19 {
                return .cardOrId
            }
        }
        
        // 4. NSDataDetector fallback for phone or address
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.phoneNumber.rawValue | NSTextCheckingResult.CheckingType.address.rawValue) {
            let matches = detector.matches(in: trimmed, options: [], range: range)
            for match in matches {
                if match.resultType == .phoneNumber {
                    return .phone
                } else if match.resultType == .address {
                    return .address
                }
            }
        }
        
        return nil
    }
}
