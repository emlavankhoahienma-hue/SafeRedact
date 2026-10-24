import SwiftUI

public enum AppTheme {
    // Primary Color Discipline
    public static let background = Color(hex: "#0B0E14")
    public static let surface = Color(hex: "#141923")
    public static let surfaceElevated = Color(hex: "#1B2230")
    public static let border = Color(hex: "#222938")
    
    // Accents
    public static let primaryAccent = Color(hex: "#10B981") // Emerald Shield
    public static let primaryCobalt = Color(hex: "#2563EB") // Cobalt Action
    public static let danger = Color(hex: "#EF4444")        // Coral Red
    public static let warning = Color(hex: "#F59E0B")       // Amber Alert
    
    // Typography
    public static let textPrimary = Color(hex: "#F3F5F8")
    public static let textSecondary = Color(hex: "#8A94A6")
    public static let textMuted = Color(hex: "#5A6475")
    
    // Spacing (8pt Grid System)
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
        public static let xxl: CGFloat = 48
    }
    
    // Radii
    public enum Radius {
        public static let sm: CGFloat = 8
        public static let md: CGFloat = 12
        public static let lg: CGFloat = 16
        public static let pill: CGFloat = 999
    }
}

public extension Color {
    init(hex: String) {
        let cleanHex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleanHex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch cleanHex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255.0,
            green: Double(g) / 255.0,
            blue: Double(b) / 255.0,
            opacity: Double(a) / 255.0
        )
    }
}
