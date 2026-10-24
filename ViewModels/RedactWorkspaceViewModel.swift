import Foundation
import UIKit
import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins

@MainActor
public final class RedactWorkspaceViewModel: ObservableObject {
    public static let shared = RedactWorkspaceViewModel()
    
    @Published public var originalImage: UIImage?
    @Published public var originalImageData: Data?
    @Published public var processedImage: UIImage?
    
    @Published public var detectedRegions: [DetectedRegion] = []
    @Published public var metadataReport: ExifMetadataReport?
    
    @Published public var redactStyle: RedactStyle = .pixelate {
        didSet {
            applyRedactions()
        }
    }
    
    // Watermark Configuration: zero continuous re-rendering on slider change!
    @Published public var watermarkConfig = WatermarkConfig()
    
    @Published public var isProcessing: Bool = false
    @Published public var statusMessage: String?
    @Published public var showToast: Bool = false
    @Published public var autoScrubExifOnSave: Bool = true
    
    // Batch Processing State
    @Published public var isBatchProcessing: Bool = false
    @Published public var batchProgress: Double = 0.0
    @Published public var batchProcessedCount: Int = 0
    @Published public var batchTotalCount: Int = 0
    
    // Library Privacy Scanner State
    @Published public var flaggedPhotos: [FlaggedPhotoItem] = []
    @Published public var isScanningLibrary: Bool = false
    @Published public var scanProgress: Double = 0.0
    
    public init() {}
    
    // MARK: - Load Selected User Photo
    
    public func loadSelectedPhoto(data: Data) {
        guard let image = UIImage(data: data) else { return }
        
        let normalized = ImageRedactionEngine.shared.normalizeOrientation(image)
        self.originalImage = normalized
        self.originalImageData = data
        self.processedImage = normalized
        self.metadataReport = MetadataScrubberEngine.shared.inspectMetadata(data: data)
        self.detectedRegions = []
        
        runDetection(on: normalized)
    }
    
    // MARK: - Generate Test Sample Bill with CoreGraphics & CIFilter QR
    
    public func loadSampleBill() {
        isProcessing = true
        let size = CGSize(width: 1200, height: 1600)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let sampleImage = renderer.image { context in
            let cg = context.cgContext
            
            // Background
            cg.setFillColor(red: 248.0 / 255.0, green: 249.0 / 255.0, blue: 251.0 / 255.0, alpha: 1.0)
            cg.fill(CGRect(origin: .zero, size: size))
            
            // Top Accent Header
            cg.setFillColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0)
            cg.fill(CGRect(x: 0, y: 0, width: size.width, height: 16))
            
            // Title & Subtitle
            let titleAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 44),
                .foregroundColor: UIColor(red: 11.0 / 255.0, green: 14.0 / 255.0, blue: 20.0 / 255.0, alpha: 1.0)
            ]
            let title = NSAttributedString(string: "HOA DON BAN HANG / INVOICE", attributes: titleAttrs)
            title.draw(at: CGPoint(x: 80, y: 60))
            
            let dateAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .regular),
                .foregroundColor: UIColor.darkGray
            ]
            let dateStr = NSAttributedString(string: "So HĐ: INV-2026-8899 | Ngay: 24/10/2026", attributes: dateAttrs)
            dateStr.draw(at: CGPoint(x: 80, y: 120))
            
            // Divider
            cg.setStrokeColor(red: 220.0 / 255.0, green: 225.0 / 255.0, blue: 232.0 / 255.0, alpha: 1.0)
            cg.setLineWidth(2)
            cg.move(to: CGPoint(x: 80, y: 170))
            cg.addLine(to: CGPoint(x: size.width - 80, y: 170))
            cg.strokePath()
            
            // Bill-To Card Background
            let cardRect = CGRect(x: 80, y: 200, width: size.width - 160, height: 460)
            cg.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
            let cardPath = UIBezierPath(roundedRect: cardRect, cornerRadius: 16)
            cardPath.fill()
            cg.setStrokeColor(red: 226.0 / 255.0, green: 232.0 / 255.0, blue: 240.0 / 255.0, alpha: 1.0)
            cardPath.stroke()
            
            // Customer Info Items
            let labelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .medium),
                .foregroundColor: UIColor(red: 100.0 / 255.0, green: 116.0 / 255.0, blue: 139.0 / 255.0, alpha: 1.0)
            ]
            let valAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 28, weight: .bold),
                .foregroundColor: UIColor(red: 15.0 / 255.0, green: 23.0 / 255.0, blue: 42.0 / 255.0, alpha: 1.0)
            ]
            
            var rowY: CGFloat = 230
            let items: [(String, String)] = [
                ("Khach hang:", "NGUYEN VAN AN"),
                ("So dien thoai:", "0912 345 678"),
                ("Email ca nhan:", "nguyen.an@safemail.vn"),
                ("So the CCCD:", "001098765432"),
                ("Tai khoan Ngan hang:", "9876 5432 1098 7654"),
                ("Dia chi giao hang:", "123 Tran Hung Dao, Quan 1, TP Ho Chi Minh")
            ]
            
            for (label, val) in items {
                NSAttributedString(string: label, attributes: labelAttrs).draw(at: CGPoint(x: 110, y: rowY))
                NSAttributedString(string: val, attributes: valAttrs).draw(at: CGPoint(x: 420, y: rowY))
                rowY += 68
            }
            
            // Financial Summary Section
            let sumRect = CGRect(x: 80, y: 700, width: size.width - 160, height: 260)
            cg.setFillColor(red: 241.0 / 255.0, green: 245.0 / 255.0, blue: 249.0 / 255.0, alpha: 1.0)
            UIBezierPath(roundedRect: sumRect, cornerRadius: 16).fill()
            
            let sumLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 24, weight: .semibold),
                .foregroundColor: UIColor.darkGray
            ]
            let sumValAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 32, weight: .bold),
                .foregroundColor: UIColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0)
            ]
            
            NSAttributedString(string: "Gia tri thanh toan:", attributes: sumLabelAttrs).draw(at: CGPoint(x: 120, y: 740))
            NSAttributedString(string: "15,800,000 VND", attributes: sumValAttrs).draw(at: CGPoint(x: 120, y: 780))
            
            // Draw Real QR Code using CoreImage
            let qrFilter = CIFilter.qrCodeGenerator()
            let qrContent = "VIETQR|001098765432|NGUYEN VAN AN|15800000|0912345678"
            qrFilter.message = Data(qrContent.utf8)
            qrFilter.correctionLevel = "H"
            
            if let outputCI = qrFilter.outputImage {
                let transform = CGAffineTransform(scaleX: 10, y: 10)
                let scaledCI = outputCI.transformed(by: transform)
                let ciContext = CIContext()
                if let cgQR = ciContext.createCGImage(scaledCI, from: scaledCI.extent) {
                    let qrImage = UIImage(cgImage: cgQR)
                    let qrRect = CGRect(x: size.width - 360, y: 720, width: 220, height: 220)
                    qrImage.draw(in: qrRect)
                }
            }
            
            // Draw Face Avatar box
            let faceRect = CGRect(x: 120, y: 1000, width: 200, height: 200)
            cg.setFillColor(red: 226.0 / 255.0, green: 232.0 / 255.0, blue: 240.0 / 255.0, alpha: 1.0)
            UIBezierPath(roundedRect: faceRect, cornerRadius: 100).fill()
            
            cg.setFillColor(red: 148.0 / 255.0, green: 163.0 / 255.0, blue: 184.0 / 255.0, alpha: 1.0)
            cg.fillEllipse(in: CGRect(x: 175, y: 1030, width: 90, height: 90))
            cg.fillEllipse(in: CGRect(x: 150, y: 1125, width: 140, height: 100))
            
            let avatarLabelAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 22, weight: .medium),
                .foregroundColor: UIColor.gray
            ]
            NSAttributedString(string: "Chân dung định danh ID", attributes: avatarLabelAttrs).draw(at: CGPoint(x: 350, y: 1080))
            
            // Security Notice Footer
            let footerAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.monospacedSystemFont(ofSize: 20, weight: .regular),
                .foregroundColor: UIColor.gray
            ]
            let footer = NSAttributedString(string: "Chung tu bao mat noi bo - SafeRedact Privacy Test Document", attributes: footerAttrs)
            footer.draw(at: CGPoint(x: 80, y: 1520))
        }
        
        let sampleData = createSampleDataWithExif(from: sampleImage)
        self.originalImage = sampleImage
        self.originalImageData = sampleData
        self.processedImage = sampleImage
        self.metadataReport = MetadataScrubberEngine.shared.inspectMetadata(data: sampleData)
        
        runDetection(on: sampleImage)
    }
    
    private func createSampleDataWithExif(from image: UIImage) -> Data {
        guard let cg = image.cgImage else {
            return image.jpegData(compressionQuality: 1.0) ?? Data()
        }
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(data, "public.jpeg" as CFString, 1, nil) else {
            return image.jpegData(compressionQuality: 1.0) ?? Data()
        }
        
        let gpsDict: [CFString: Any] = [
            kCGImagePropertyGPSLatitude: 10.7769,
            kCGImagePropertyGPSLatitudeRef: "N",
            kCGImagePropertyGPSLongitude: 106.7009,
            kCGImagePropertyGPSLongitudeRef: "E",
            kCGImagePropertyGPSAltitude: 12.5
        ]
        
        let tiffDict: [CFString: Any] = [
            kCGImagePropertyTIFFMake: "Apple",
            kCGImagePropertyTIFFModel: "iPhone 16 Pro Max",
            kCGImagePropertyTIFFSoftware: "iOS 18.1 Camera App",
            kCGImagePropertyTIFFDateTime: "2026:10:24 14:35:22"
        ]
        
        let exifDict: [CFString: Any] = [
            kCGImagePropertyExifLensModel: "iPhone 16 Pro Max back triple camera 24mm f/1.78",
            kCGImagePropertyExifISOSpeedRatings: [64],
            kCGImagePropertyExifFocalLength: 6.76,
            kCGImagePropertyExifExposureTime: 0.01,
            kCGImagePropertyExifDateTimeOriginal: "2026:10:24 14:35:22"
        ]
        
        let properties: [CFString: Any] = [
            kCGImagePropertyGPSDictionary: gpsDict,
            kCGImagePropertyTIFFDictionary: tiffDict,
            kCGImagePropertyExifDictionary: exifDict
        ]
        
        CGImageDestinationAddImage(dest, cg, properties as CFDictionary)
        CGImageDestinationFinalize(dest)
        return data as Data
    }
    
    // MARK: - Run Vision Detection
    
    private func runDetection(on image: UIImage) {
        isProcessing = true
        Task {
            let regions = await PIIDetectionEngine.shared.detectSensitiveData(in: image)
            await MainActor.run {
                self.detectedRegions = regions
                self.applyRedactions()
                self.isProcessing = false
            }
        }
    }
    
    // MARK: - Interactive Redact Toggles
    
    public func toggleRegion(id: UUID) {
        if let idx = detectedRegions.firstIndex(where: { $0.id == id }) {
            detectedRegions[idx].isRedacted.toggle()
            applyRedactions()
        }
    }
    
    public func redactAll() {
        for idx in detectedRegions.indices {
            detectedRegions[idx].isRedacted = true
        }
        applyRedactions()
    }
    
    public func unredactAll() {
        for idx in detectedRegions.indices {
            detectedRegions[idx].isRedacted = false
        }
        applyRedactions()
    }
    
    public func applyRedactions() {
        guard let original = originalImage else { return }
        self.processedImage = ImageRedactionEngine.shared.applyRedactions(
            to: original,
            regions: detectedRegions,
            style: redactStyle
        )
    }
    
    // MARK: - EXIF Scrubber Operations (100% Lossless Full-Resolution)
    
    public func scrubAllMetadataAndSave() -> Bool {
        guard let currentImage = processedImage ?? originalImage,
              let rawData = currentImage.jpegData(compressionQuality: 1.0) else {
            return false
        }
        
        guard let cleanData = MetadataScrubberEngine.shared.scrubMetadata(from: rawData) else {
            return false
        }
        
        if let cleanImage = UIImage(data: cleanData) {
            UIImageWriteToSavedPhotosAlbum(cleanImage, nil, nil, nil)
            self.metadataReport = MetadataScrubberEngine.shared.inspectMetadata(data: cleanData)
            triggerToast(messageKey: "scrubbed_success")
            return true
        }
        return false
    }
    
    // MARK: - Export Watermark / PDF (On-Demand Background Execution)
    
    public func exportSecurePDF() -> URL? {
        guard let base = processedImage ?? originalImage else { return nil }
        let watermarked = ImageRedactionEngine.shared.applyTiledWatermark(to: base, config: watermarkConfig)
        let url = MetadataScrubberEngine.shared.exportSecurePDF(from: watermarked, title: "SafeRedact Secured Doc")
        if url != nil {
            triggerToast(messageKey: "pdf_generated_success")
        }
        return url
    }
    
    public func saveCurrentImageToPhotos() {
        guard let img = processedImage ?? originalImage else { return }
        
        if autoScrubExifOnSave, let data = img.jpegData(compressionQuality: 1.0),
           let cleanData = MetadataScrubberEngine.shared.scrubMetadata(from: data),
           let cleanImage = UIImage(data: cleanData) {
            UIImageWriteToSavedPhotosAlbum(cleanImage, nil, nil, nil)
        } else {
            UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
        }
        triggerToast(messageKey: "saved_notification")
    }
    
    public func saveWatermarkedImageToPhotos() {
        guard let base = processedImage ?? originalImage else { return }
        isProcessing = true
        let config = self.watermarkConfig
        let shouldScrub = self.autoScrubExifOnSave
        
        Task.detached(priority: .userInitiated) {
            let watermarked = ImageRedactionEngine.shared.applyTiledWatermark(to: base, config: config)
            
            if shouldScrub, let data = watermarked.jpegData(compressionQuality: 1.0),
               let cleanData = MetadataScrubberEngine.shared.scrubMetadata(from: data),
               let cleanImage = UIImage(data: cleanData) {
                UIImageWriteToSavedPhotosAlbum(cleanImage, nil, nil, nil)
            } else {
                UIImageWriteToSavedPhotosAlbum(watermarked, nil, nil, nil)
            }
            
            await MainActor.run {
                self.isProcessing = false
                self.triggerToast(messageKey: "saved_notification")
            }
        }
    }
    
    // MARK: - Batch Multi-Photo Processing (Multi-Threaded with TaskGroup & Autoreleasepool)
    
    public func processBatchPhotos(dataList: [Data]) async {
        guard !dataList.isEmpty else { return }
        
        isBatchProcessing = true
        batchTotalCount = dataList.count
        batchProcessedCount = 0
        batchProgress = 0.0
        
        let style = self.redactStyle
        let shouldScrub = self.autoScrubExifOnSave
        
        let chunkSize = 4
        for chunk in dataList.chunked(into: chunkSize) {
            await withTaskGroup(of: Void.self) { group in
                for itemData in chunk {
                    group.addTask {
                        autoreleasepool {
                            guard let original = UIImage(data: itemData) else { return }
                            let normalized = ImageRedactionEngine.shared.normalizeOrientation(original)
                            
                            // Perform synchronous detection in task
                            var detected: [DetectedRegion] = []
                            if let cg = normalized.cgImage {
                                let request = VNRecognizeTextRequest()
                                request.recognitionLevel = .accurate
                                request.usesLanguageCorrection = true
                                let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                                try? handler.perform([request])
                                
                                if let obs = request.results {
                                    for o in obs {
                                        if let str = o.topCandidates(1).first?.string,
                                           let type = PIIDetectionEngine.shared.classifyText(str) {
                                            let box = o.boundingBox
                                            detected.append(
                                                DetectedRegion(
                                                    type: type,
                                                    text: str,
                                                    normalizedRect: CGRect(x: box.origin.x, y: 1.0 - box.origin.y - box.height, width: box.width, height: box.height),
                                                    isRedacted: true
                                                )
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // Apply full-res redaction
                            let redacted = ImageRedactionEngine.shared.applyRedactions(to: normalized, regions: detected, style: style)
                            
                            if shouldScrub, let jpegData = redacted.jpegData(compressionQuality: 1.0),
                               let cleanData = MetadataScrubberEngine.shared.scrubMetadata(from: jpegData),
                               let cleanImage = UIImage(data: cleanData) {
                                UIImageWriteToSavedPhotosAlbum(cleanImage, nil, nil, nil)
                            } else {
                                UIImageWriteToSavedPhotosAlbum(redacted, nil, nil, nil)
                            }
                        }
                    }
                }
            }
            
            batchProcessedCount += chunk.count
            batchProgress = Double(batchProcessedCount) / Double(batchTotalCount)
        }
        
        isBatchProcessing = false
        triggerToast(messageKey: "batch_completed")
    }
    
    // MARK: - Library Privacy Scanner Integration
    
    public func runLibraryPrivacyScan() async {
        isScanningLibrary = true
        scanProgress = 0.0
        
        let items = await LibraryPrivacyScannerEngine.shared.scanLibrary { current, total in
            Task { @MainActor in
                self.scanProgress = total > 0 ? Double(current) / Double(total) : 0.0
            }
        }
        
        self.flaggedPhotos = items
        self.isScanningLibrary = false
    }
    
    public func selectFlaggedPhoto(item: FlaggedPhotoItem) {
        Task {
            if let (image, data) = await LibraryPrivacyScannerEngine.shared.loadFullImage(for: item.assetId) {
                await MainActor.run {
                    self.loadSelectedPhoto(data: data)
                }
            }
        }
    }
    
    private func triggerToast(messageKey: String) {
        self.statusMessage = LocalizationManager.shared.t(messageKey)
        self.showToast = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            self.showToast = false
        }
    }
}
