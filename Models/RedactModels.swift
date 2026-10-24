import SwiftUI
import Photos

// MARK: - Sensitive Data Types

public enum PIIType: String, CaseIterable, Identifiable, Codable {
    case phone
    case cardOrId
    case email
    case address
    case face
    case barcode
    case secret
    case document
    case custom
    
    public var id: String { rawValue }
    
    public var badgeColor: Color {
        switch self {
        case .phone:
            return Color(hex: "#EF4444") // Coral Red
        case .cardOrId:
            return Color(hex: "#F59E0B") // Amber
        case .email:
            return Color(hex: "#3B82F6") // Blue
        case .address:
            return Color(hex: "#8B5CF6") // Purple
        case .face:
            return Color(hex: "#10B981") // Emerald
        case .barcode:
            return Color(hex: "#06B6D4") // Cyan
        case .secret:
            return Color(hex: "#F43F5E") // Rose Red
        case .document:
            return Color(hex: "#6366F1") // Indigo
        case .custom:
            return Color(hex: "#EC4899") // Pink
        }
    }
}

// MARK: - Detected Sensitive Region

public struct DetectedRegion: Identifiable, Equatable {
    public let id: UUID
    public let type: PIIType
    public let text: String
    public let normalizedRect: CGRect // Vision normalized coordinates (top-left origin [0,0] to [1,1])
    public var isRedacted: Bool
    
    public init(
        id: UUID = UUID(),
        type: PIIType,
        text: String,
        normalizedRect: CGRect,
        isRedacted: Bool = true
    ) {
        self.id = id
        self.type = type
        self.text = text
        self.normalizedRect = normalizedRect
        self.isRedacted = isRedacted
    }
}

// MARK: - Redaction Visual Styles

public enum RedactStyle: String, CaseIterable, Identifiable {
    case pixelate = "pixelate"
    case blur = "blur"
    case solid = "solid"
    
    public var id: String { rawValue }
}

// MARK: - EXIF & GPS Metadata Report

public struct ExifMetadataReport: Equatable {
    public let latitude: Double?
    public let longitude: Double?
    public let altitude: Double?
    public let cameraMake: String?
    public let cameraModel: String?
    public let lensModel: String?
    public let dateTimeOriginal: String?
    public let software: String?
    public let iso: Int?
    public let focalLength: Double?
    public let exposureTime: Double?
    public let rawPropertiesCount: Int
    
    public var hasGPS: Bool {
        latitude != nil && longitude != nil
    }
    
    public var hasSensitiveMetadata: Bool {
        hasGPS || dateTimeOriginal != nil || cameraModel != nil
    }
    
    public init(
        latitude: Double? = nil,
        longitude: Double? = nil,
        altitude: Double? = nil,
        cameraMake: String? = nil,
        cameraModel: String? = nil,
        lensModel: String? = nil,
        dateTimeOriginal: String? = nil,
        software: String? = nil,
        iso: Int? = nil,
        focalLength: Double? = nil,
        exposureTime: Double? = nil,
        rawPropertiesCount: Int = 0
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.cameraMake = cameraMake
        self.cameraModel = cameraModel
        self.lensModel = lensModel
        self.dateTimeOriginal = dateTimeOriginal
        self.software = software
        self.iso = iso
        self.focalLength = focalLength
        self.exposureTime = exposureTime
        self.rawPropertiesCount = rawPropertiesCount
    }
}

// MARK: - Watermark Configuration

public struct WatermarkConfig: Equatable {
    public var text: String
    public var opacity: Double
    public var angleDegrees: Double
    public var fontSize: CGFloat
    public var spacing: CGFloat
    
    public init(
        text: String = "CHI DUNG XAC THUC TAI KHOAN",
        opacity: Double = 0.28,
        angleDegrees: Double = -30.0,
        fontSize: CGFloat = 16.0,
        spacing: CGFloat = 120.0
    ) {
        self.text = text
        self.opacity = opacity
        self.angleDegrees = angleDegrees
        self.fontSize = fontSize
        self.spacing = spacing
    }
}

// MARK: - Batch Processing Models

public struct BatchItem: Identifiable, Equatable {
    public let id: String
    public let thumbnail: UIImage?
    public var status: BatchStatus
    public var regionsCount: Int
    
    public enum BatchStatus: Equatable {
        case queued
        case processing
        case completed
        case failed(String)
    }
    
    public init(id: String = UUID().uuidString, thumbnail: UIImage? = nil, status: BatchStatus = .queued, regionsCount: Int = 0) {
        self.id = id
        self.thumbnail = thumbnail
        self.status = status
        self.regionsCount = regionsCount
    }
}

// MARK: - Library Privacy Scanner Models

public enum FlaggedCategory: String, CaseIterable, Identifiable {
    case documentCard
    case personalPII
    case gpsLeak
    
    public var id: String { rawValue }
}

public struct FlaggedPhotoItem: Identifiable, Equatable {
    public let id: String
    public let assetId: String
    public let category: FlaggedCategory
    public let title: String
    public let subtitle: String
    public let creationDate: Date?
    
    public init(
        id: String = UUID().uuidString,
        assetId: String,
        category: FlaggedCategory,
        title: String,
        subtitle: String,
        creationDate: Date? = nil
    ) {
        self.id = id
        self.assetId = assetId
        self.category = category
        self.title = title
        self.subtitle = subtitle
        self.creationDate = creationDate
    }
}
