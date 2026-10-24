# SafeRedact

SafeRedact is an on-device privacy and metadata shield for iOS 16+. It features on-device AI redaction of sensitive visual elements (phone numbers, payment card details, citizen IDs, emails, physical addresses, faces, and QR/barcodes), lossless EXIF/GPS scrubbing, and repeating diagonal security watermark rendering with PDF export.

---

## Key Capabilities

### 1. Smart Redact (On-Device Vision AI)
- Automatic detection of personal identifying information (PII) using Apple Vision Framework (`VNRecognizeTextRequest`, `VNDetectFaceRectanglesRequest`, `VNDetectBarcodesRequest`).
- Categorization across phone numbers, payment cards, national IDs, email addresses, street addresses, faces, and QR/barcodes.
- Interactive bounding boxes: tap any box to toggle redaction state.
- Redaction styles:
  - Pixelate (Mosaic filter via `CIPixellate`)
  - Gaussian Blur (`CIGaussianBlur`)
  - Solid Privacy Bar (`#0B0E14`)
- Built-in sample invoice generator rendered directly via `CoreGraphics` for instant offline testing.

### 2. EXIF & GPS Scrubber
- Inspects embedded metadata dictionaries (`{GPS}`, `{TIFF}`, `{Exif}`).
- Identifies geolocation coordinates (latitude, longitude, altitude), camera make/model, lens model, software version, and original timestamps.
- Losslessly strips all metadata tags using `CGImageDestination` without recompression artifacts.

### 3. ID Watermark Studio & Secure PDF
- Generates diagonal repeated security text watermarks (for example, "CHI DUNG XAC THUC TAI KHOAN") to prevent identity document misuse.
- Configurable opacity, rotation angle, and typography.
- Single-tap export to encrypted / flat PDF document via `PDFKit`.

### 4. Settings & Internationalization
- Bilingual support: Vietnamese and English (`LocalizationManager.swift`).
- Zero network requests. All Vision AI and image manipulations run strictly on the device hardware.

---

## Architectural Layout

```text
SafeRedact/
├── LICENSE                               # MIT License
├── README.md                             # Documentation
├── Info.plist                            # Permissions & capabilities
├── generate_pbxproj.py                   # Xcode project generator
├── SafeRedact.xcodeproj/                 # Xcode project
├── App/
│   └── SafeRedactApp.swift               # Application entry point
├── Theme/
│   ├── AppTheme.swift                    # Dark palette (#0B0E14) & 8pt grid
│   └── VectorIconLibrary.swift           # Vector Shape/Path icons (Lucide / Feather)
├── Models/
│   └── RedactModels.swift                # Region, metadata report & watermark models
├── Engines/
│   ├── PIIDetectionEngine.swift          # Vision & Regex PII detectors
│   ├── ImageRedactionEngine.swift        # CoreImage filters & watermark renderer
│   └── MetadataScrubberEngine.swift      # ImageIO metadata stripper & PDFKit exporter
├── Services/
│   └── LocalizationManager.swift         # Dynamic bilingual localization
├── ViewModels/
│   └── RedactWorkspaceViewModel.swift    # Application coordinator & sample generator
├── Views/
│   ├── MainTabView.swift                 # 4-tab container
│   ├── SmartRedactView.swift             # Interactive redaction canvas
│   ├── MetadataScrubberView.swift        # EXIF analysis and scrubbing
│   ├── WatermarkStudioView.swift         # Diagonal watermark & PDF studio
│   └── SettingsView.swift                # Preferences and app credentials
└── tests/
    └── test_safe_redact.py               # Unit tests (Zero-Emoji, PII regex, metadata logic)
```

---

## Building and Packaging

### Requirements
- macOS 14+ with Xcode 15+ (iOS 16.0+ SDK)
- Python 3.10+ (for project generator and test suite)

### Verification
Run the verification suite locally:
```bash
python3 tests/test_safe_redact.py
```

### Xcode Project Generation
```bash
python3 generate_pbxproj.py
```

### Command-Line Compilation
```bash
xcodebuild -project SafeRedact.xcodeproj \
  -scheme SafeRedact \
  -configuration Release \
  -sdk iphoneos \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build
```

### Unsigned IPA Packaging
```bash
mkdir -p Payload
cp -R build/Release-iphoneos/SafeRedact.app Payload/
zip -qr SafeRedact-Unsigned.ipa Payload
```

---

## License

MIT License. Copyright (c) 2026 ace4youblade.
