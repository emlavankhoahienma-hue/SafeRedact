import SwiftUI
import QuickLook

public struct WatermarkStudioView: View {
    @ObservedObject var vm = RedactWorkspaceViewModel.shared
    @ObservedObject var loc = LocalizationManager.shared
    
    @State private var pdfURL: URL?
    @State private var showShareSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Header
                        headerCard
                        
                        // Watermark Smooth Canvas Preview
                        if let img = vm.processedImage ?? vm.originalImage {
                            canvasPreviewCard(baseImage: img)
                            
                            // Watermark Controls
                            controlsCard
                            
                            // Action Buttons
                            actionsCard
                        } else {
                            noImageCard
                        }
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
                
                // Toast Alert
                if vm.showToast, let msg = vm.statusMessage {
                    VStack {
                        Spacer()
                        HStack(spacing: AppTheme.Spacing.sm) {
                            VectorIcon(.checkmark, size: 18, color: AppTheme.primaryAccent)
                            Text(msg)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.surfaceElevated)
                        .clipShape(Capsule())
                        .overlay(Capsule().stroke(AppTheme.primaryAccent, lineWidth: 1))
                        .shadow(color: Color.black.opacity(0.4), radius: 8, y: 4)
                        .padding(.bottom, AppTheme.Spacing.xl)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle(loc.t("tab_watermark"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                if let url = pdfURL {
                    ActivityView(activityItems: [url])
                }
            }
        }
    }
    
    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VectorIcon(.fileLock, size: 20, color: AppTheme.primaryAccent)
                Text(loc.t("watermark_title"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            Text(loc.t("watermark_subtitle"))
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    // Smooth 60-120 FPS SwiftUI Canvas Preview without full-res image re-renders
    private func canvasPreviewCard(baseImage: UIImage) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            ZStack {
                Image(uiImage: baseImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 320)
                    .frame(maxWidth: .infinity)
                
                // Hardware accelerated Canvas overlay
                Canvas { context, size in
                    let text = Text(vm.watermarkConfig.text)
                        .font(.system(size: vm.watermarkConfig.fontSize * 0.75, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.white.opacity(vm.watermarkConfig.opacity))
                    
                    let resolved = context.resolve(text)
                    let textSize = resolved.measure(in: size)
                    
                    let stepX = max(textSize.width + 30, vm.watermarkConfig.spacing * 0.6)
                    let stepY = max(textSize.height + 24, vm.watermarkConfig.spacing * 0.45)
                    
                    let diagonal = sqrt(size.width * size.width + size.height * size.height)
                    let start = -diagonal
                    let end = diagonal * 2
                    
                    context.translateBy(x: size.width * 0.5, y: size.height * 0.5)
                    context.rotate(by: .degrees(vm.watermarkConfig.angleDegrees))
                    context.translateBy(x: -size.width * 0.5, y: -size.height * 0.5)
                    
                    var y = start
                    while y < end {
                        var x = start
                        while x < end {
                            context.draw(resolved, at: CGPoint(x: x, y: y), anchor: .center)
                            x += stepX
                        }
                        y += stepY
                    }
                }
                .allowsHitTesting(false)
            }
            .cornerRadius(AppTheme.Radius.sm)
            .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.border, lineWidth: 1))
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var controlsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.md) {
            // Text Input
            VStack(alignment: .leading, spacing: 6) {
                Text(loc.t("watermark_text"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                
                TextField("Watermark text", text: $vm.watermarkConfig.text)
                    .font(.system(size: 14, weight: .medium))
                    .padding(.horizontal, AppTheme.Spacing.sm)
                    .padding(.vertical, 10)
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(AppTheme.Radius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.border, lineWidth: 1))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            // Opacity Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(loc.t("opacity"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f%%", vm.watermarkConfig.opacity * 100))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.primaryAccent)
                }
                Slider(value: $vm.watermarkConfig.opacity, in: 0.1...0.8, step: 0.02)
                    .tint(AppTheme.primaryAccent)
            }
            
            // Angle Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(loc.t("angle"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f deg", vm.watermarkConfig.angleDegrees))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.primaryCobalt)
                }
                Slider(value: $vm.watermarkConfig.angleDegrees, in: -60.0...60.0, step: 5.0)
                    .tint(AppTheme.primaryCobalt)
            }
            
            // Font Size Slider
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(loc.t("font_size"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textSecondary)
                    Spacer()
                    Text(String(format: "%.0f pt", vm.watermarkConfig.fontSize))
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(AppTheme.textPrimary)
                }
                Slider(value: $vm.watermarkConfig.fontSize, in: 12.0...36.0, step: 2.0)
                    .tint(AppTheme.textPrimary)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var actionsCard: some View {
        VStack(spacing: AppTheme.Spacing.sm) {
            Button {
                vm.saveWatermarkedImageToPhotos()
            } label: {
                HStack(spacing: 8) {
                    VectorIcon(.download, size: 18, color: Color.white)
                    Text(loc.t("save_watermarked"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primaryAccent)
                .cornerRadius(AppTheme.Radius.sm)
            }
            
            Button {
                if let url = vm.exportSecurePDF() {
                    self.pdfURL = url
                    self.showShareSheet = true
                }
            } label: {
                HStack(spacing: 8) {
                    VectorIcon(.fileLock, size: 18, color: Color.white)
                    Text(loc.t("export_pdf"))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(AppTheme.primaryCobalt)
                .cornerRadius(AppTheme.Radius.sm)
            }
        }
    }
    
    private var noImageCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            VectorIcon(.fileLock, size: 48, color: AppTheme.textSecondary)
                .padding(.top, AppTheme.Spacing.md)
            
            Text(loc.t("no_image_loaded"))
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(loc.t("no_image_hint"))
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
            
            Button {
                vm.loadSampleBill()
            } label: {
                Text(loc.t("load_sample_bill"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color.white)
                    .padding(.horizontal, AppTheme.Spacing.lg)
                    .padding(.vertical, 12)
                    .background(AppTheme.primaryCobalt)
                    .cornerRadius(AppTheme.Radius.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.border, lineWidth: 1))
    }
}

public struct ActivityView: UIViewControllerRepresentable {
    public let activityItems: [Any]
    public let applicationActivities: [UIActivity]? = nil
    
    public func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
    }
    
    public func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
