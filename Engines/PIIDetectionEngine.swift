import Foundation
import UIKit
import Vision

public final class PIIDetectionEngine {
    public static let shared = PIIDetectionEngine()
    
    private init() {}
    
    // Regular expressions for privacy patterns
    private let phoneRegex = try? NSRegularExpression(
        pattern: #"(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}"#,
        options: .caseInsensitive
    )
    
    // Vietnam phone numbers: 09x, 08x, 07x, 03x, 05x, +84...
    private let vnPhoneRegex = try? NSRegularExpression(
        pattern: #"(?:(?:\+?84|0)(?:3[2-9]|5[25689]|7[06-9]|8[1-9]|9[0-9]|2\d{2}))[-.\s]?\d{3,4}[-.\s]?\d{3,4}"#,
        options: .caseInsensitive
    )
    
    private let emailRegex = try? NSRegularExpression(
        pattern: #"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}"#,
        options: .caseInsensitive
    )
    
    // 9-19 digits (Bank accounts, Vietnamese CCCD 12 digits, CMND 9 digits, Credit/Debit cards 16 digits)
    private let cardOrIdRegex = try? NSRegularExpression(
        pattern: #"\b(?:\d[ -]*?){9,19}\b"#,
        options: []
    )
    
    // Passwords, PINs, CVV, Secret tokens
    private let secretRegex = try? NSRegularExpression(
        pattern: #"(?i)(?:mat\s*khau|password|passcode|pin|cvv|cvc|api[_-]?key|secret)[:\s=]+([^\s,;]{3,32})"#,
        options: .caseInsensitive
    )
    
    public func detectSensitiveData(in image: UIImage) async -> [DetectedRegion] {
        guard let cgImage = image.cgImage else { return [] }
        
        var regions: [DetectedRegion] = []
        
        // 1. Vision Text Recognition (Accurate + Language Correction + vi-VN & en-US)
        let textRegions = await detectTextRegions(in: cgImage)
        regions.append(contentsOf: textRegions)
        
        // 2. Vision Face Detection
        let faceRegions = await detectFaceRegions(in: cgImage)
        regions.append(contentsOf: faceRegions)
        
        // 3. Vision Barcode / QR Detection
        let barcodeRegions = await detectBarcodeRegions(in: cgImage)
        regions.append(contentsOf: barcodeRegions)
        
        // 4. Vision Document & ID Card Segmentation
        let docRegions = await detectDocumentRegions(in: cgImage)
        regions.append(contentsOf: docRegions)
        
        return regions
    }
    
    // MARK: - Vision Accurate Text Recognition
    
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
                    
                    let visionBox = observation.boundingBox
                    let uiRect = CGRect(
                        x: visionBox.origin.x,
                        y: 1.0 - visionBox.origin.y - visionBox.height,
                        width: visionBox.width,
                        height: visionBox.height
                    )
                    
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
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["vi-VN", "en-US"]
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
    
    // MARK: - Vision Document Segmentation
    
    private func detectDocumentRegions(in cgImage: CGImage) async -> [DetectedRegion] {
        await withCheckedContinuation { continuation in
            let request = VNDetectDocumentSegmentationRequest { request, error in
                guard error == nil, let observations = request.results as? [VNRectangleObservation] else {
                    continuation.resume(returning: [])
                    return
                }
                
                var detected: [DetectedRegion] = []
                for doc in observations {
                    let box = doc.boundingBox
                    // Only flag if document occupies a substantial sub-region (e.g. ID card inside photo)
                    if box.width < 0.95 || box.height < 0.95 {
                        let uiRect = CGRect(
                            x: box.origin.x,
                            y: 1.0 - box.origin.y - box.height,
                            width: box.width,
                            height: box.height
                        )
                        detected.append(
                            DetectedRegion(
                                type: .document,
                                text: "Document Bounds",
                                normalizedRect: uiRect,
                                isRedacted: false // Default to unredacted boundary so user can choose
                            )
                        )
                    }
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
        
        // 1. Password / Secret check
        if let secretRegex = secretRegex, secretRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            return .secret
        }
        
        // 2. Email check
        if let emailRegex = emailRegex, emailRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            return .email
        }
        
        // 3. Vietnam Phone check
        if let vnPhoneRegex = vnPhoneRegex, vnPhoneRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            return .phone
        }
        
        // 4. General Phone check
        if let phoneRegex = phoneRegex, phoneRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            let digitsOnly = trimmed.filter { $0.isNumber }
            if digitsOnly.count >= 9 && digitsOnly.count <= 13 {
                return .phone
            }
        }
        
        // 5. Card / Account / Citizen ID check
        if let cardRegex = cardOrIdRegex, cardRegex.firstMatch(in: trimmed, options: [], range: range) != nil {
            let digitsOnly = trimmed.filter { $0.isNumber }
            if digitsOnly.count >= 9 && digitsOnly.count <= 19 {
                return .cardOrId
            }
        }
        
        // 6. NSDataDetector fallback for phone or address
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
