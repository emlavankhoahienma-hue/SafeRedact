import SwiftUI

// MARK: - Vector Shapes (Lucide / Feather Standard Vector Icons)

public struct ShieldShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.22))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.95),
            control: CGPoint(x: w * 0.88, y: h * 0.65)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.12, y: h * 0.22),
            control: CGPoint(x: w * 0.12, y: h * 0.65)
        )
        path.closeSubpath()
        return path
    }
}

public struct EyeOffShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Eye outline
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.5))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.9, y: h * 0.5),
            control: CGPoint(x: w * 0.5, y: h * 0.15)
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.1, y: h * 0.5),
            control: CGPoint(x: w * 0.5, y: h * 0.85)
        )
        
        // Diagonal strike
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.85))
        return path
    }
}

public struct QrCodeShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cornerSize = min(w, h) * 0.35
        let pad = min(w, h) * 0.08
        
        // Top-left finder
        path.addRect(CGRect(x: pad, y: pad, width: cornerSize, height: cornerSize))
        path.addRect(CGRect(x: pad + cornerSize * 0.25, y: pad + cornerSize * 0.25, width: cornerSize * 0.5, height: cornerSize * 0.5))
        
        // Top-right finder
        path.addRect(CGRect(x: w - pad - cornerSize, y: pad, width: cornerSize, height: cornerSize))
        path.addRect(CGRect(x: w - pad - cornerSize + cornerSize * 0.25, y: pad + cornerSize * 0.25, width: cornerSize * 0.5, height: cornerSize * 0.5))
        
        // Bottom-left finder
        path.addRect(CGRect(x: pad, y: h - pad - cornerSize, width: cornerSize, height: cornerSize))
        path.addRect(CGRect(x: pad + cornerSize * 0.25, y: h - pad - cornerSize + cornerSize * 0.25, width: cornerSize * 0.5, height: cornerSize * 0.5))
        
        // Central data bits
        path.addRect(CGRect(x: w * 0.45, y: h * 0.45, width: w * 0.15, height: h * 0.15))
        path.addRect(CGRect(x: w * 0.65, y: h * 0.65, width: w * 0.15, height: h * 0.15))
        path.addRect(CGRect(x: w * 0.45, y: h * 0.70, width: w * 0.12, height: h * 0.12))
        return path
    }
}

public struct FingerprintShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5
        let cy = h * 0.5
        
        // Outer loop
        path.addArc(center: CGPoint(x: cx, y: cy), radius: w * 0.4, startAngle: .degrees(140), endAngle: .degrees(40), clockwise: false)
        // Mid loop
        path.addArc(center: CGPoint(x: cx, y: cy + h * 0.05), radius: w * 0.28, startAngle: .degrees(150), endAngle: .degrees(30), clockwise: false)
        // Inner loop
        path.addArc(center: CGPoint(x: cx, y: cy + h * 0.1), radius: w * 0.16, startAngle: .degrees(160), endAngle: .degrees(20), clockwise: false)
        // Core whorl
        path.move(to: CGPoint(x: cx, y: cy + h * 0.15))
        path.addLine(to: CGPoint(x: cx, y: cy + h * 0.35))
        return path
    }
}

public struct FileLockShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Document page
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.9))
        path.closeSubpath()
        
        // Fold corner
        path.move(to: CGPoint(x: w * 0.6, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.3))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.3))
        
        // Lock body
        path.addRoundedRect(in: CGRect(x: w * 0.35, y: h * 0.52, width: w * 0.3, height: h * 0.26), cornerSize: CGSize(width: 3, height: 3))
        // Lock shackle
        path.addArc(center: CGPoint(x: w * 0.5, y: h * 0.52), radius: w * 0.1, startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        return path
    }
}

public struct SlidersShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Track 1
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.25))
        // Thumb 1
        path.addEllipse(in: CGRect(x: w * 0.35 - h * 0.1, y: h * 0.15, width: h * 0.2, height: h * 0.2))
        
        // Track 2
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.5))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.5))
        // Thumb 2
        path.addEllipse(in: CGRect(x: w * 0.65 - h * 0.1, y: h * 0.4, width: h * 0.2, height: h * 0.2))
        
        // Track 3
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.75))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.75))
        // Thumb 3
        path.addEllipse(in: CGRect(x: w * 0.25 - h * 0.1, y: h * 0.65, width: h * 0.2, height: h * 0.2))
        return path
    }
}

public struct TrashShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Lid
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.25))
        path.move(to: CGPoint(x: w * 0.4, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.4, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.6, y: h * 0.25))
        
        // Can body
        path.move(to: CGPoint(x: w * 0.28, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.32, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.68, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.72, y: h * 0.25))
        
        // Inner ribs
        path.move(to: CGPoint(x: w * 0.43, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.43, y: h * 0.72))
        path.move(to: CGPoint(x: w * 0.57, y: h * 0.38))
        path.addLine(to: CGPoint(x: w * 0.57, y: h * 0.72))
        return path
    }
}

public struct CheckmarkShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.15, y: h * 0.52))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.8))
        path.addLine(to: CGPoint(x: w * 0.88, y: h * 0.22))
        return path
    }
}

public struct DownloadShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Arrow stem
        path.move(to: CGPoint(x: w * 0.5, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
        // Arrow head
        path.move(to: CGPoint(x: w * 0.3, y: h * 0.48))
        path.addLine(to: CGPoint(x: w * 0.5, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.48))
        // Tray base
        path.move(to: CGPoint(x: w * 0.2, y: h * 0.65))
        path.addLine(to: CGPoint(x: w * 0.2, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.85))
        path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.65))
        return path
    }
}

public struct CameraShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Flash bump
        path.move(to: CGPoint(x: w * 0.35, y: h * 0.25))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.15))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.25))
        
        // Body
        path.addRoundedRect(in: CGRect(x: w * 0.12, y: h * 0.25, width: w * 0.76, height: h * 0.62), cornerSize: CGSize(width: 6, height: 6))
        // Lens circle
        path.addEllipse(in: CGRect(x: w * 0.34, y: h * 0.38, width: w * 0.32, height: h * 0.36))
        return path
    }
}

public struct CrosshairScanShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let arm = min(w, h) * 0.25
        
        // Top-left
        path.move(to: CGPoint(x: w * 0.1, y: h * 0.1 + arm))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.1 + arm, y: h * 0.1))
        
        // Top-right
        path.move(to: CGPoint(x: w * 0.9 - arm, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.1))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.1 + arm))
        
        // Bottom-right
        path.move(to: CGPoint(x: w * 0.9, y: h * 0.9 - arm))
        path.addLine(to: CGPoint(x: w * 0.9, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.9 - arm, y: h * 0.9))
        
        // Bottom-left
        path.move(to: CGPoint(x: w * 0.1 + arm, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.9))
        path.addLine(to: CGPoint(x: w * 0.1, y: h * 0.9 - arm))
        return path
    }
}

public struct SparklesShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5
        let cy = h * 0.5
        
        // 4-point star
        path.move(to: CGPoint(x: cx, y: h * 0.08))
        path.addQuadCurve(to: CGPoint(x: w * 0.92, y: cy), control: CGPoint(x: cx + w * 0.08, y: cy - h * 0.08))
        path.addQuadCurve(to: CGPoint(x: cx, y: h * 0.92), control: CGPoint(x: cx + w * 0.08, y: cy + h * 0.08))
        path.addQuadCurve(to: CGPoint(x: w * 0.08, y: cy), control: CGPoint(x: cx - w * 0.08, y: cy + h * 0.08))
        path.addQuadCurve(to: CGPoint(x: cx, y: h * 0.08), control: CGPoint(x: cx - w * 0.08, y: cy - h * 0.08))
        path.closeSubpath()
        return path
    }
}

// MARK: - Reusable Vector Icon View Component

public struct VectorIcon: View {
    public enum IconKind {
        case shield
        case eyeOff
        case qrCode
        case fingerprint
        case fileLock
        case sliders
        case trash
        case checkmark
        case download
        case camera
        case crosshairScan
        case sparkles
    }
    
    public let kind: IconKind
    public var size: CGFloat = 20
    public var color: Color = AppTheme.textPrimary
    public var lineWidth: CGFloat = 2
    
    public init(_ kind: IconKind, size: CGFloat = 20, color: Color = AppTheme.textPrimary, lineWidth: CGFloat = 2) {
        self.kind = kind
        self.size = size
        self.color = color
        self.lineWidth = lineWidth
    }
    
    public var body: some View {
        Group {
            switch kind {
            case .shield:
                ShieldShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .eyeOff:
                EyeOffShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .qrCode:
                QrCodeShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth * 0.8, lineCap: .round, lineJoin: .round))
            case .fingerprint:
                FingerprintShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .fileLock:
                FileLockShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .sliders:
                SlidersShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .trash:
                TrashShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .checkmark:
                CheckmarkShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .download:
                DownloadShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .camera:
                CameraShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .crosshairScan:
                CrosshairScanShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            case .sparkles:
                SparklesShape()
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(width: size, height: size)
    }
}
