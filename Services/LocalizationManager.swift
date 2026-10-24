import SwiftUI

public final class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()
    
    public enum Language: String, CaseIterable, Identifiable {
        case vi = "vi"
        case en = "en"
        
        public var id: String { rawValue }
        
        public var displayName: String {
            switch self {
            case .vi: return "Tiếng Việt"
            case .en: return "English"
            }
        }
    }
    
    @Published public var language: Language {
        didSet {
            UserDefaults.standard.set(language.rawValue, forKey: "app_language")
        }
    }
    
    private init() {
        if let saved = UserDefaults.standard.string(forKey: "app_language"),
           let lang = Language(rawValue: saved) {
            self.language = lang
        } else {
            self.language = .vi
        }
    }
    
    public func t(_ key: String) -> String {
        Self.translations[language]?[key] ?? Self.translations[.en]?[key] ?? key
    }
    
    private static let translations: [Language: [String: String]] = [
        .vi: [
            // Tabs
            "tab_smart_redact": "Smart Redact",
            "tab_exif_scrubber": "EXIF Scrubber",
            "tab_watermark": "ID Watermark",
            "tab_settings": "Cài đặt",
            
            // Smart Redact View
            "smart_redact_title": "AI Che Dữ Liệu Nhạy Cảm",
            "smart_redact_subtitle": "Tự nhận diện SĐT, CCCD, Email, QR, Mặt & che ngay trên máy",
            "load_sample_bill": "Nạp Ảnh Mẫu Thử Nghiệm",
            "select_from_library": "Chọn Ảnh Từ Thư Viện",
            "select_multiple": "Chọn Nhiều Ảnh",
            "change_photo": "Đổi Ảnh",
            "detected_regions": "Vùng Nhạy Cảm Phát Hiện",
            "tap_hint": "Chạm vào ô đang che để Mở, chạm ô viền đứt để Che lại",
            "redact_all": "Che Tất Cả",
            "unredact_all": "Bỏ Che Tất Cả",
            "style_pixelate": "Vỡ Hạt Mosaic",
            "style_blur": "Làm Mờ Kính",
            "style_solid": "Thanh Che Kín",
            "save_image": "Lưu Vào Ảnh (Gốc 100%)",
            "share_image": "Chia Sẻ Ảnh",
            "no_image_loaded": "Chưa có ảnh nào được chọn",
            "no_image_hint": "Bấm 'Nạp Ảnh Mẫu' hoặc chọn ảnh từ thư viện để bắt đầu",
            "scanning_pii": "Đang quét dữ liệu nhạy cảm bằng Vision AI...",
            "batch_processing": "Xử Lý Hàng Loạt",
            "batch_progress": "Tiến độ xử lý",
            "batch_completed": "Đã xử lý xong toàn bộ ảnh",
            "scan_library_title": "Quét Thư Viện Tìm Ảnh Rò Rỉ",
            "scan_library_btn": "Quét Thư Viện Bảo Mật",
            "scan_in_progress": "Đang quét thư viện...",
            "flagged_documents": "Giấy tờ, CCCD & Hóa đơn",
            "flagged_pii": "Mã QR, SĐT & Thông tin",
            "flagged_gps": "Ảnh lộ tọa độ định vị GPS",
            "safe_library_notice": "Không phát hiện ảnh có nguy cơ rò rỉ",
            
            // PII Types
            "pii_phone": "Số điện thoại",
            "pii_card": "Thẻ / CCCD / STK",
            "pii_email": "Email",
            "pii_address": "Địa chỉ",
            "pii_face": "Khuôn mặt",
            "pii_barcode": "Mã QR / Barcode",
            "pii_secret": "Mật khẩu / PIN",
            "pii_document": "Vùng giấy tờ",
            "pii_custom": "Tự chọn",
            
            // EXIF Scrubber View
            "exif_title": "Soi & Xóa Dữ Liệu Ẩn",
            "exif_subtitle": "Bảo vệ thông tin định vị GPS, thiết bị và dấu vết chụp",
            "scrub_action": "Xóa Sạch EXIF & Lưu Bản Gốc 100%",
            "gps_location": "Tọa Độ Định Vị GPS",
            "no_gps_leaks": "Không phát hiện dữ liệu GPS trong ảnh",
            "latitude": "Vĩ độ",
            "longitude": "Kinh độ",
            "altitude": "Độ cao",
            "device_info": "Thông Tin Thiết Bị Chụp",
            "make": "Hãng sản xuất",
            "model": "Dòng máy",
            "lens": "Ống kính",
            "software": "Phần mềm",
            "capture_details": "Thông Số Chụp Gốc",
            "datetime": "Thời gian chụp gốc",
            "iso": "Chỉ số ISO",
            "focal_length": "Tiêu cự",
            "exposure": "Thời gian phơi sáng",
            "total_tags": "Tổng số thẻ metadata ẩn",
            "scrubbed_success": "Đã lột sạch toàn bộ EXIF/GPS thành công",
            
            // Watermark View
            "watermark_title": "Đóng Dấu Bảo Vệ Giấy Tờ",
            "watermark_subtitle": "Xem trước tức thì không giật lag & xuất file PDF bảo mật",
            "watermark_text": "Nội Dung Dấu Bảo Vệ",
            "opacity": "Độ Mờ Lớp Phủ",
            "angle": "Góc Nghiêng",
            "font_size": "Cỡ Chữ",
            "export_pdf": "Xuất File PDF",
            "save_watermarked": "Lưu Ảnh Đã Đóng Dấu (Gốc 100%)",
            "pdf_generated_success": "Đã tạo tài liệu PDF bảo mật thành công",
            
            // Settings View
            "settings_title": "Cài Đặt & Bản Quyền",
            "language_section": "Ngôn Ngữ Ứng Dụng",
            "defaults_section": "Tùy Chỉnh Mặc Định",
            "default_redact_style": "Kiểu che mặc định",
            "auto_scrub_exif": "Tự động xóa EXIF khi lưu ảnh",
            "app_info_section": "Thông Tin Ứng Dụng",
            "app_name_label": "Ứng dụng",
            "version_label": "Phiên bản",
            "developer_label": "Nhà phát triển",
            "privacy_architecture": "Kiến Trúc Bảo Mật",
            "zero_cloud_guarantee": "100% On-Device Neural Vision - Không gửi bất kỳ dữ liệu nào lên mạng",
            "saved_notification": "Đã lưu ảnh chất lượng gốc thành công vào Thư viện"
        ],
        .en: [
            // Tabs
            "tab_smart_redact": "Smart Redact",
            "tab_exif_scrubber": "EXIF Scrubber",
            "tab_watermark": "ID Watermark",
            "tab_settings": "Settings",
            
            // Smart Redact View
            "smart_redact_title": "AI Sensitive Data Redaction",
            "smart_redact_subtitle": "Detect phone, ID cards, email, QR, faces and redact fully on-device",
            "load_sample_bill": "Load Sample Invoice",
            "select_from_library": "Choose From Photo Library",
            "select_multiple": "Select Multiple Photos",
            "change_photo": "Change Photo",
            "detected_regions": "Detected Sensitive Regions",
            "tap_hint": "Tap redacted box to reveal, tap dashed box to re-redact",
            "redact_all": "Redact All",
            "unredact_all": "Unredact All",
            "style_pixelate": "Pixelate Mosaic",
            "style_blur": "Glass Blur",
            "style_solid": "Solid Bar",
            "save_image": "Save to Photos (100% Lossless)",
            "share_image": "Share Image",
            "no_image_loaded": "No Image Selected",
            "no_image_hint": "Tap 'Load Sample Invoice' or pick an image from library to begin",
            "scanning_pii": "Scanning sensitive data with Vision AI...",
            "batch_processing": "Batch Processing",
            "batch_progress": "Processing progress",
            "batch_completed": "Completed batch processing",
            "scan_library_title": "Scan Photo Library for Leaks",
            "scan_library_btn": "Scan Privacy Risks",
            "scan_in_progress": "Scanning library...",
            "flagged_documents": "ID Cards, Passports & Bills",
            "flagged_pii": "QR Codes, Phones & Secrets",
            "flagged_gps": "Photos with Leaked GPS Coordinates",
            "safe_library_notice": "No privacy risk photos detected",
            
            // PII Types
            "pii_phone": "Phone Number",
            "pii_card": "Card / ID / Account",
            "pii_email": "Email Address",
            "pii_address": "Physical Address",
            "pii_face": "Human Face",
            "pii_barcode": "QR / Barcode",
            "pii_secret": "Password / PIN",
            "pii_document": "Document Bounds",
            "pii_custom": "Custom Region",
            
            // EXIF Scrubber View
            "exif_title": "Inspect & Scrub Hidden Data",
            "exif_subtitle": "Safeguard GPS geolocation, device fingerprints, and metadata tags",
            "scrub_action": "Scrub All Metadata & Save Clean (100% Lossless)",
            "gps_location": "GPS Geolocation Coordinates",
            "no_gps_leaks": "No GPS metadata found in this photo",
            "latitude": "Latitude",
            "longitude": "Longitude",
            "altitude": "Altitude",
            "device_info": "Capture Device Hardware",
            "make": "Manufacturer",
            "model": "Device Model",
            "lens": "Camera Lens",
            "software": "Software",
            "capture_details": "Original Capture Parameters",
            "datetime": "Original Date & Time",
            "iso": "ISO Speed",
            "focal_length": "Focal Length",
            "exposure": "Exposure Time",
            "total_tags": "Total Hidden Metadata Tags",
            "scrubbed_success": "Stripped 100% of EXIF/GPS metadata successfully",
            
            // Watermark View
            "watermark_title": "ID & Document Watermark",
            "watermark_subtitle": "Instant 60-120 FPS live preview & secured PDF export",
            "watermark_text": "Watermark Text Content",
            "opacity": "Watermark Opacity",
            "angle": "Rotation Angle",
            "font_size": "Font Size",
            "export_pdf": "Export PDF Document",
            "save_watermarked": "Save Watermarked Photo (100% Lossless)",
            "pdf_generated_success": "Secured PDF document generated successfully",
            
            // Settings View
            "settings_title": "Settings & Copyright",
            "language_section": "Application Language",
            "defaults_section": "Default Preferences",
            "default_redact_style": "Default Redaction Style",
            "auto_scrub_exif": "Automatically scrub EXIF on save",
            "app_info_section": "Application Information",
            "app_name_label": "Application",
            "version_label": "Version",
            "developer_label": "Developer",
            "privacy_architecture": "Privacy Architecture",
            "zero_cloud_guarantee": "100% On-Device Neural Vision - Zero network transmission",
            "saved_notification": "Photo saved at original quality to Library"
        ]
    ]
}
