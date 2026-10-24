import Foundation
import UIKit
import ImageIO
import UniformTypeIdentifiers
import PDFKit

public final class MetadataScrubberEngine {
    public static let shared = MetadataScrubberEngine()
    
    private init() {}
    
    // Inspect and extract hidden metadata parameters from image data
    public func inspectMetadata(data: Data) -> ExifMetadataReport {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else {
            return ExifMetadataReport()
        }
        
        let rawCount = properties.count
        
        // GPS Data
        var lat: Double?
        var lon: Double?
        var alt: Double?
        if let gps = properties[kCGImagePropertyGPSDictionary] as? [CFString: Any] {
            if let latitude = gps[kCGImagePropertyGPSLatitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLatitudeRef] as? String ?? "N"
                lat = (ref == "S") ? -latitude : latitude
            }
            if let longitude = gps[kCGImagePropertyGPSLongitude] as? Double {
                let ref = gps[kCGImagePropertyGPSLongitudeRef] as? String ?? "E"
                lon = (ref == "W") ? -longitude : longitude
            }
            if let altitude = gps[kCGImagePropertyGPSAltitude] as? Double {
                alt = altitude
            }
        }
        
        // TIFF Data (Camera make, model, software, original date)
        var make: String?
        var model: String?
        var software: String?
        var dateOriginal: String?
        if let tiff = properties[kCGImagePropertyTIFFDictionary] as? [CFString: Any] {
            make = tiff[kCGImagePropertyTIFFMake] as? String
            model = tiff[kCGImagePropertyTIFFModel] as? String
            software = tiff[kCGImagePropertyTIFFSoftware] as? String
            dateOriginal = tiff[kCGImagePropertyTIFFDateTime] as? String
        }
        
        // EXIF Data (Lens, ISO, focal length, exposure time)
        var lens: String?
        var iso: Int?
        var focal: Double?
        var exposure: Double?
        if let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any] {
            lens = exif[kCGImagePropertyExifLensModel] as? String
            if let isoArray = exif[kCGImagePropertyExifISOSpeedRatings] as? [Int], let first = isoArray.first {
                iso = first
            }
            focal = exif[kCGImagePropertyExifFocalLength] as? Double
            exposure = exif[kCGImagePropertyExifExposureTime] as? Double
            if dateOriginal == nil {
                dateOriginal = exif[kCGImagePropertyExifDateTimeOriginal] as? String
            }
        }
        
        return ExifMetadataReport(
            latitude: lat,
            longitude: lon,
            altitude: alt,
            cameraMake: make,
            cameraModel: model,
            lens: lens,
            dateTimeOriginal: dateOriginal,
            software: software,
            iso: iso,
            focalLength: focal,
            exposureTime: exposure,
            rawPropertiesCount: rawCount
        )
    }
    
    // Losslessly strip all metadata (EXIF, GPS, TIFF, IPTC, MakerNotes) using CGImageDestination
    public func scrubMetadata(from imageData: Data, format: UTType = .jpeg) -> Data? {
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let cgImage = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
            return nil
        }
        
        let destinationData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            destinationData,
            format.identifier as CFString,
            1,
            nil
        ) else {
            return nil
        }
        
        // Clean metadata dictionary with all tracking properties explicitly cleared
        let cleanProperties: [CFString: Any] = [
            kCGImageDestinationLossless: true,
            kCGImagePropertyGPSDictionary: [:] as [CFString: Any],
            kCGImagePropertyExifDictionary: [:] as [CFString: Any],
            kCGImagePropertyTIFFDictionary: [:] as [CFString: Any],
            kCGImagePropertyIPTCDictionary: [:] as [CFString: Any],
            kCGImagePropertyMakerAppleDictionary: [:] as [CFString: Any]
        ]
        
        CGImageDestinationAddImage(destination, cgImage, cleanProperties as CFDictionary)
        
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        
        return destinationData as Data
    }
    
    // Export image as secure single-page or multi-page PDF document
    public func exportSecurePDF(from image: UIImage, title: String = "SafeRedact Document") -> URL? {
        let pdfData = NSMutableData()
        let pageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        
        UIGraphicsBeginPDFContextToData(pdfData, pageRect, [
            kCGPDFContextTitle as String: title,
            kCGPDFContextCreator as String: "SafeRedact Privacy Engine"
        ])
        
        UIGraphicsBeginPDFPageWithInfo(pageRect, nil)
        image.draw(in: pageRect)
        UIGraphicsEndPDFContext()
        
        let tempUrl = FileManager.default.temporaryDirectory
            .appendingPathComponent("SafeRedact_\(UUID().uuidString).pdf")
        
        do {
            try pdfData.write(to: tempUrl, options: .atomic)
            return tempUrl
        } catch {
            return nil
        }
    }
}
