import Foundation
import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins

public final class ImageRedactionEngine {
    public static let shared = ImageRedactionEngine()
    
    private let ciContext: CIContext
    
    private init() {
        self.ciContext = CIContext(options: [.useSoftwareRenderer: false])
    }
    
    // Normalize image orientation to .up to prevent coordinate mismatch
    public func normalizeOrientation(_ image: UIImage) -> UIImage {
        if image.imageOrientation == .up {
            return image
        }
        
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: image.size, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }
    }
    
    // Apply redactions with selected visual style
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
        
        let size = normalizedImage.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = normalizedImage.scale
        
        switch style {
        case .solid:
            return applySolidRedaction(to: normalizedImage, regions: activeRegions, size: size, format: format)
        case .pixelate:
            return applyCoreImageFilter(to: normalizedImage, regions: activeRegions, filterName: "CIPixellate", scaleParam: max(size.width, size.height) * 0.04)
        case .blur:
            return applyCoreImageFilter(to: normalizedImage, regions: activeRegions, filterName: "CIGaussianBlur", scaleParam: max(size.width, size.height) * 0.035)
        }
    }
    
    private func applySolidRedaction(
        to image: UIImage,
        regions: [DetectedRegion],
        size: CGSize,
        format: UIGraphicsImageRendererFormat
    ) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
            
            let cg = context.cgContext
            cg.setFillColor(red: 11.0 / 255.0, green: 14.0 / 255.0, blue: 20.0 / 255.0, alpha: 1.0) // #0B0E14
            
            for region in regions {
                let rect = CGRect(
                    x: region.normalizedRect.origin.x * size.width,
                    y: region.normalizedRect.origin.y * size.height,
                    width: region.normalizedRect.width * size.width,
                    height: region.normalizedRect.height * size.height
                )
                let insetRect = rect.insetBy(dx: -2, dy: -2)
                let path = UIBezierPath(roundedRect: insetRect, cornerRadius: 4)
                path.fill()
                
                // Add a subtle border
                cg.setStrokeColor(red: 34.0 / 255.0, green: 41.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0)
                cg.setLineWidth(1.0)
                path.stroke()
            }
        }
    }
    
    private func applyCoreImageFilter(
        to image: UIImage,
        regions: [DetectedRegion],
        filterName: String,
        scaleParam: CGFloat
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
        
        guard let filteredCI = filter?.outputImage else { return image }
        
        // Render filtered image
        guard let filteredCG = ciContext.createCGImage(filteredCI, from: ciImage.extent) else {
            return image
        }
        let filteredImage = UIImage(cgImage: filteredCG, scale: image.scale, orientation: .up)
        
        // Composite filtered regions over original
        let size = image.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = image.scale
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        
        return renderer.image { context in
            image.draw(in: CGRect(origin: .zero, size: size))
            
            let cg = context.cgContext
            for region in regions {
                let rect = CGRect(
                    x: region.normalizedRect.origin.x * size.width,
                    y: region.normalizedRect.origin.y * size.height,
                    width: region.normalizedRect.width * size.width,
                    height: region.normalizedRect.height * size.height
                )
                let expanded = rect.insetBy(dx: -2, dy: -2)
                
                cg.saveGState()
                let clipPath = UIBezierPath(roundedRect: expanded, cornerRadius: 4).cgPath
                cg.addPath(clipPath)
                cg.clip()
                filteredImage.draw(in: CGRect(origin: .zero, size: size))
                cg.restoreGState()
                
                // Border highlight
                cg.setStrokeColor(red: 16.0 / 255.0, green: 185.0 / 255.0, blue: 129.0 / 255.0, alpha: 0.6)
                cg.setLineWidth(1.5)
                UIBezierPath(roundedRect: expanded, cornerRadius: 4).stroke()
            }
        }
    }
    
    // Apply repeating diagonal security watermark across the image
    public func applyTiledWatermark(to image: UIImage, config: WatermarkConfig) -> UIImage {
        let normalized = normalizeOrientation(image)
        let size = normalized.size
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = normalized.scale
        
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            normalized.draw(in: CGRect(origin: .zero, size: size))
            
            let cg = context.cgContext
            cg.saveGState()
            
            let font = UIFont.monospacedSystemFont(ofSize: config.fontSize, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: UIColor.white.withAlphaComponent(config.opacity)
            ]
            let attrString = NSAttributedString(string: config.text, attributes: attributes)
            let textSize = attrString.size()
            
            let radians = config.angleDegrees * .pi / 180.0
            let stepX = max(textSize.width + 40, config.spacing)
            let stepY = max(textSize.height + 40, config.spacing * 0.7)
            
            let diagonal = sqrt(size.width * size.width + size.height * size.height)
            let start = -diagonal
            let end = diagonal * 2
            
            cg.translateBy(x: size.width * 0.5, y: size.height * 0.5)
            cg.rotate(by: CGFloat(radians))
            cg.translateBy(x: -size.width * 0.5, y: -size.height * 0.5)
            
            var y = start
            while y < end {
                var x = start
                while x < end {
                    attrString.draw(at: CGPoint(x: x, y: y))
                    x += stepX
                }
                y += stepY
            }
            
            cg.restoreGState()
        }
    }
}
