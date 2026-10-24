import Foundation
import UIKit
import Photos
import Vision

public final class LibraryPrivacyScannerEngine {
    public static let shared = LibraryPrivacyScannerEngine()
    
    private let cacheKey = "safe_redact_scanned_asset_ids"
    private var scannedCache: Set<String> = []
    
    private init() {
        if let saved = UserDefaults.standard.stringArray(forKey: cacheKey) {
            scannedCache = Set(saved)
        }
    }
    
    private func saveCache() {
        UserDefaults.standard.set(Array(scannedCache), forKey: cacheKey)
    }
    
    // Request Photos authorization
    public func requestAuthorization() async -> Bool {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            return true
        }
        let requested = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return requested == .authorized || requested == .limited
    }
    
    // Scan library with multi-threaded TaskGroup and autoreleasepool
    public func scanLibrary(
        maxAssetsToScan: Int = 100,
        progress: @escaping @Sendable (Int, Int) -> Void
    ) async -> [FlaggedPhotoItem] {
        let hasAuth = await requestAuthorization()
        guard hasAuth else { return [] }
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        fetchOptions.fetchLimit = maxAssetsToScan
        
        let fetchResult = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let total = fetchResult.count
        if total == 0 { return [] }
        
        var assetsToAnalyze: [PHAsset] = []
        for i in 0..<total {
            let asset = fetchResult.object(at: i)
            assetsToAnalyze.append(asset)
        }
        
        let manager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .fastFormat
        requestOptions.resizeMode = .fast
        
        var flaggedItems: [FlaggedPhotoItem] = []
        var scannedCounter = 0
        
        // Concurrent task group bounded to 4 parallel workers
        let chunkSize = 4
        for chunk in assetsToAnalyze.chunked(into: chunkSize) {
            let results = await withTaskGroup(of: FlaggedPhotoItem?.self) { group in
                for asset in chunk {
                    group.addTask {
                        return autoreleasepool {
                            // 1. Check for immediate GPS metadata leak
                            if let loc = asset.location {
                                return FlaggedPhotoItem(
                                    assetId: asset.localIdentifier,
                                    category: .gpsLeak,
                                    title: "GPS Leaked",
                                    subtitle: String(format: "Lat: %.4f, Lon: %.4f", loc.coordinate.latitude, loc.coordinate.longitude),
                                    creationDate: asset.creationDate
                                )
                            }
                            
                            // 2. Load low-res thumbnail for AI privacy inspection
                            var targetImage: UIImage?
                            let targetSize = CGSize(width: 800, height: 800)
                            manager.requestImage(
                                for: asset,
                                targetSize: targetSize,
                                contentMode: .aspectFit,
                                options: requestOptions
                            ) { img, _ in
                                targetImage = img
                            }
                            
                            guard let image = targetImage, let cg = image.cgImage else { return nil }
                            
                            // 3. Vision fast scan for PII, Barcodes & Documents
                            let request = VNRecognizeTextRequest()
                            request.recognitionLevel = .fast
                            request.usesLanguageCorrection = false
                            
                            let handler = VNImageRequestHandler(cgImage: cg, options: [:])
                            try? handler.perform([request])
                            
                            guard let observations = request.results else { return nil }
                            var combinedText = ""
                            for obs in observations {
                                if let text = obs.topCandidates(1).first?.string {
                                    combinedText += " " + text
                                }
                            }
                            
                            // Check for document/ID cards
                            let docKeywords = ["cccd", "cmnd", "can cuoc", "identity", "invoice", "hoa don", "bank", "account", "so the", "stk"]
                            let lower = combinedText.lowercased()
                            for kw in docKeywords {
                                if lower.contains(kw) {
                                    return FlaggedPhotoItem(
                                        assetId: asset.localIdentifier,
                                        category: .documentCard,
                                        title: "ID / Invoice Detected",
                                        subtitle: "Contains keyword: \(kw.uppercased())",
                                        creationDate: asset.creationDate
                                    )
                                }
                            }
                            
                            // Check for phone/secret/email
                            if let type = PIIDetectionEngine.shared.classifyText(combinedText) {
                                return FlaggedPhotoItem(
                                    assetId: asset.localIdentifier,
                                    category: .personalPII,
                                    title: "PII Detected",
                                    subtitle: "\(type.rawValue.capitalized) found in image",
                                    creationDate: asset.creationDate
                                )
                            }
                            
                            return nil
                        }
                    }
                }
                
                var chunkResults: [FlaggedPhotoItem] = []
                for await item in group {
                    if let item = item {
                        chunkResults.append(item)
                    }
                }
                return chunkResults
            }
            
            flaggedItems.append(contentsOf: results)
            scannedCounter += chunk.count
            progress(scannedCounter, total)
        }
        
        return flaggedItems
    }
    
    // Load full-resolution image for selected asset
    public func loadFullImage(for assetId: String) async -> (UIImage, Data)? {
        let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetId], options: nil)
        guard let asset = result.firstObject else { return nil }
        
        let manager = PHImageManager.default()
        let options = PHImageRequestOptions()
        options.isSynchronous = false
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        
        return await withCheckedContinuation { continuation in
            manager.requestImageDataAndOrientation(for: asset, options: options) { data, _, _, _ in
                if let data = data, let img = UIImage(data: data) {
                    continuation.resume(returning: (img, data))
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}

// Helper chunking extension
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
