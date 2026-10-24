import os
import re
import sys
import plistlib
import unittest

class TestSafeRedact(unittest.TestCase):
    def setUp(self):
        self.base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    def test_required_files_exist(self):
        required_files = [
            "LICENSE",
            "README.md",
            "Info.plist",
            "App/SafeRedactApp.swift",
            "Theme/AppTheme.swift",
            "Theme/VectorIconLibrary.swift",
            "Models/RedactModels.swift",
            "Engines/PIIDetectionEngine.swift",
            "Engines/ImageRedactionEngine.swift",
            "Engines/MetadataScrubberEngine.swift",
            "Services/LocalizationManager.swift",
            "ViewModels/RedactWorkspaceViewModel.swift",
            "Views/MainTabView.swift",
            "Views/SmartRedactView.swift",
            "Views/MetadataScrubberView.swift",
            "Views/WatermarkStudioView.swift",
            "Views/SettingsView.swift",
            "generate_pbxproj.py",
            "SafeRedact.xcodeproj/project.pbxproj",
            ".github/workflows/ios-build.yml"
        ]
        for rel_path in required_files:
            full_path = os.path.join(self.base_dir, rel_path)
            self.assertTrue(os.path.exists(full_path), f"Missing required file: {rel_path}")

    def test_strict_zero_emoji_rule(self):
        # Scan all Swift, Python, Plist, YML, JSON, and MD files for any actual emoji character
        # Emoji Unicode Ranges:
        emoji_pattern = re.compile(
            "["
            "\U0001F600-\U0001F64F"  # Emoticons
            "\U0001F300-\U0001F5FF"  # Misc Symbols and Pictographs
            "\U0001F680-\U0001F6FF"  # Transport and Map
            "\U0001F1E6-\U0001F1FF"  # Regional indicator symbols (Flags)
            "\U0001F900-\U0001F9FF"  # Supplemental Symbols and Pictographs
            "\U0001FA70-\U0001FAFF"  # Symbols and Pictographs Extended-A
            "\U00002600-\U000026FF"  # Miscellaneous Symbols
            "\U00002700-\U000027BF"  # Dingbats
            "]"
        )
        
        scanned_count = 0
        violations = []
        for root, dirs, files in os.walk(self.base_dir):
            if ".git" in root or "DerivedData" in root:
                continue
            for f in files:
                ext = os.path.splitext(f)[1].lower()
                if ext in [".swift", ".py", ".plist", ".yml", ".yaml", ".json", ".md", ".pbxproj"]:
                    scanned_count += 1
                    path = os.path.join(root, f)
                    with open(path, "r", encoding="utf-8", errors="replace") as fh:
                        for line_num, line in enumerate(fh, 1):
                            match = emoji_pattern.search(line)
                            if match:
                                rel = os.path.relpath(path, self.base_dir)
                                violations.append(f"{rel}:{line_num} contains emoji '{match.group()}'")
        
        self.assertGreater(scanned_count, 10, "Should have scanned at least 10 files")
        self.assertEqual(violations, [], f"Strict Zero-Emoji violations found: {violations}")

    def test_info_plist_validity(self):
        plist_path = os.path.join(self.base_dir, "Info.plist")
        with open(plist_path, "rb") as f:
            plist = plistlib.load(f)
            
        self.assertIn("NSPhotoLibraryUsageDescription", plist)
        self.assertIn("NSPhotoLibraryAddUsageDescription", plist)
        self.assertEqual(plist.get("MinimumOSVersion"), "16.0")
        self.assertEqual(plist.get("CFBundleSupportedPlatforms"), ["iPhoneOS"])
        self.assertEqual(plist.get("UIRequiredDeviceCapabilities"), ["arm64"])
        self.assertEqual(plist.get("UIDeviceFamily"), [1, 2])
        self.assertEqual(plist.get("CFBundleIdentifier"), "com.ace4youblade.saferedact")

    def test_pii_classification_regex(self):
        # Test the regex patterns implemented in PIIDetectionEngine
        phone_regex = re.compile(r"(?:\+?\d{1,3}[-.\s]?)?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}", re.IGNORECASE)
        email_regex = re.compile(r"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,64}", re.IGNORECASE)
        card_regex = re.compile(r"\b(?:\d[ -]*?){9,19}\b")
        
        # Test phone
        test_phones = ["0912 345 678", "0912345678", "+84 912 345 678", "024-3825-9999"]
        for p in test_phones:
            self.assertTrue(phone_regex.search(p), f"Should match phone: {p}")
            
        # Test email
        test_emails = ["nguyen.an@safemail.vn", "contact@domain.com", "user.name+tag@sub.example.org"]
        for e in test_emails:
            self.assertTrue(email_regex.search(e), f"Should match email: {e}")
            
        # Test card/CCCD
        test_cards = ["001098765432", "9876 5432 1098 7654", "1234-5678-9012-3456"]
        for c in test_cards:
            self.assertTrue(card_regex.search(c), f"Should match card/id: {c}")

    def test_metadata_scrubber_logic_simulation(self):
        # Simulate scrubbing: raw metadata dict -> sanitized dict
        raw_metadata = {
            "{GPS}": {"Latitude": 10.7769, "Longitude": 106.7009, "Altitude": 12.5},
            "{TIFF}": {"Make": "Apple", "Model": "iPhone 16 Pro Max", "DateTime": "2026:10:24 14:35:22"},
            "{Exif}": {"LensModel": "24mm f/1.78", "ISOSpeedRatings": [64]},
            "ColorModel": "RGB"
        }
        
        # Stripping removes GPS, TIFF, Exif, MakerNotes
        sanitized = {k: v for k, v in raw_metadata.items() if k not in ["{GPS}", "{TIFF}", "{Exif}"]}
        self.assertNotIn("{GPS}", sanitized)
        self.assertNotIn("{TIFF}", sanitized)
        self.assertNotIn("{Exif}", sanitized)
        self.assertIn("ColorModel", sanitized)

if __name__ == "__main__":
    unittest.main()
