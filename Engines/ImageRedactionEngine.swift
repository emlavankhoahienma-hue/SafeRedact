import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

public final class ImageRedactionEngine {
    public static let shared = ImageRedactionEngine()
    
    private let ciContext: CIContext
    
    private init() {
        self.ciContext = CIContext(options: [
            .useSoftwareRenderer: false,
            .priorityRequestLow: false
        ])
    }
    
    // Normalize image orientation to .up at 100% native pixel resolution without any distortion
    public func normalizeOrientation(_ image: UIImage) -> UIImage {
        guard image.imageOrientation != .up else { return image }
        
        // image.size already has correct width and height for rotated orientations (.right, .left, etc.)
        let targetSize = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: targetSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: targetSize))
        }
    }
    
    // Apply redactions preserving 100% lossless full-resolution pixels
    public func applyRedactions(
        to image: UIImage,
        regions: [DetectedRegion],
        style: RedactStyle
    ) -> UIImage {
        let normalizedImage = normalizeOrientation(image)
        let activeRegions = regions.filter { $0.isRedacted }
        
        if activeRegions.isEmpty {
            return normalizedImage
        }
        
        let pixelSize = normalizedImage.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = normalizedImage.scale
        format.opaque = false
        
        switch style {
        case .solid:
            return applySolidRedaction(
                to: normalizedImage,
                regions: activeRegions,
                pixelSize: pixelSize,
                format: format
            )
        case .pixelate:
            let scaleParam = max(pixelSize.width, pixelSize.height) * 0.035
            return applyCoreImageFilter(
                to: normalizedImage,
                regions: activeRegions,
                filterName: "CIPixellate",
                scaleParam: scaleParam,
                pixelSize: pixelSize
            )
        case .blur:
            let scaleParam = max(pixelSize.width, pixelSize.height) * 0.03
            return applyCoreImageFilter(
                to: normalizedImage,
                regions: activeRegions,
                filterName: "CIGaussianBlur",
                scaleParam: scaleParam,
                pixelSize: pixelSize
            )
        }
    }
    
    private func applySolidRedaction(
        to image: UIImage,
        regions: [DetectedRegion],
        pixelSize: CGSize,
        format: UIGraphicsImageRendererFormat
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
            
            let cg = context.cgContext
            cg.setFillColor(red: 11.0 / 255.0, green: 14.0 / 255.0, blue: 20.0 / 255.0, alpha: 1.0) // #0B0E14
            
            for region in regions {
                let rect = CGRect(
                    x: region.normalizedRect.origin.x * pixelSize.width,
                    y: region.normalizedRect.origin.y * pixelSize.height,
                    width: region.normalizedRect.width * pixelSize.width,
                    height: region.normalizedRect.height * pixelSize.height
                )
                let insetRect = rect.insetBy(dx: -4, dy: -4)
                let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 8)
                path.fill()
                
                // Solid border highlight
                cg.setStrokeColor(red: 34.0 / 255.0, green: 41.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0)
                cg.setLineWidth(2.0)
                path.stroke()
            }
        }
    }
    
    private func applyCoreImageFilter(
        to image: UIImage,
        regions: [DetectedRegion],
        filterName: String,
        scaleParam: CGFloat,
        pixelSize: CGSize
    ) -> UIImage {
        guard let cgImage = image.cgImage else { return image }
        let ciImage = CIImage(cgImage: cgImage)
        
        let filter: CIFilter?
        if filterName == "CIPixellate" {
            let pix = CIFilter.pixellate()
            pix.inputImage = ciImage
            pix.scale = Float(scaleParam)
            filter = pix
        } else {
            let blur = CIFilter.gaussianBlur()
            blur.inputImage = ciImage
            blur.radius = Float(scaleParam)
            filter = blur
        }
        
        guard let filteredCI = filter?.outputImage,
              let filteredCG = ciContext.createCGImage(filteredCI, from: ciImage.extent) else {
            return image
        }
        
        let filteredImage = UIImage(cgImage: filteredCG, scale: 1.0, orientation: .up)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1.0
        format.opaque = false
        
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: pixelSize))
            
            let cg = context.cgContext
            for region in regions {
                let rect = CGRect(
                    x: region.normalizedRect.origin.x * pixelSize.width,
                    y: region.normalizedRect.origin.y * pixelSize.height,
                    width: region.normalizedRect.width * pixelSize.width,
                    height: region.normalizedRect.height * pixelSize.height
                )
                let expanded = rect.insetBy(dx: -4, dy: -4)
                
                cg.saveGState()
                let clipPath = UIBezierPath(roundedRect: expanded, cornerRadius: 8).cgPath
                cg.addPath(clipPath)
                cg.clip()
                filteredImage.draw(in: CGRect(origin: .zero, size: pixelSize))
                cg.restoreGState()
                
                // Border highlight
                cg.setStrokeColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 0.8)
                cg.setLineWidth(2.5)
                UIBezierPath(roundedRect: expanded, cornerRadius: 8).stroke()
            }
        }
    }
    
    // Apply repeating diagonal security watermark across full-resolution image
    public func applyTiledWatermark(to image: UIImage, config: WatermarkConfig) -> UIImage {
        let normalized = normalizeOrientation(image)
        let pixelSize = normalized.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = normalized.scale
        format.opaque = false
        
        // Scale font size proportionally for high-resolution images
        let scaleFactor = max(pixelSize.width, pixelSize.height) / 1200.0
        let effectiveFontSize = max(14.0, config.fontSize * scaleFactor)
        let effectiveSpacing = max(80.0, config.spacing * scaleFactor)
        
        let renderer = UIGraphicsImageRenderer(size: pixelSize, format: format)
        return renderer.image { context in
            normalized.draw(in: CGRect(origin: .zero, size: pixelSize))
            
            let cgContext = context.cgContext
            cgContext.saveGState()
            
            let font = UIFont.monospacedSystemFont(ofSize: effectiveFontSize, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(config.opacity)
            ]
            let attrString = NSAttributedString(string: config.text, attributes: attributes)
            let textSize = attrString.size()
            
            let radians = config.angleDegrees * .pi / 180.0
            let stepX = max(textSize.width + 40 * scaleFactor, effectiveSpacing)
            let stepY = max(textSize.height + 30 * scaleFactor, effectiveSpacing * 0.7)
            
            let diagonal = sqrt(pixelSize.width * pixelSize.width + pixelSize.height * pixelSize.height)
            let start = -diagonal
            let end = diagonal * 2
            
            cgContext.translateBy(x: pixelSize.width * 0.5, y: pixelSize.height * 0.5)
            cgContext.rotate(by: CGFloat(radians))
            cgContext.translateBy(x: -pixelSize.width * 0.5, y: -pixelSize.height * 0.5)
            
            var y = start
            while y < end {
                var x = start
                while x < end {
                    attrString.draw(at: CGPoint(x: x, y: y))
                    x += stepX
                }
                y += stepY
            }
            
            cgContext.restoreGState()
        }
    }
}
