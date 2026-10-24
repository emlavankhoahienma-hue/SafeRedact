import SwiftUI
import PhotosUI

public struct SmartRedactView: View {
    @ObservedObject var vm = RedactWorkspaceViewModel.shared
    @ObservedObject var loc = LocalizationManager.shared
    
    @State private var selectedItem: PhotosPickerItem?
    @State private var showShareSheet: Bool = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Top Action Bar
                    topActionBar
                        .padding(.horizontal, AppTheme.Spacing.md)
                        .padding(.vertical, AppTheme.Spacing.sm)
                        .background(AppTheme.surface)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundColor(AppTheme.border),
                            alignment: .bottom
                        )
                    
                    // Main Content Canvas
                    ScrollView {
                        VStack(spacing: AppTheme.Spacing.md) {
                            if let image = vm.processedImage ?? vm.originalImage {
                                imageViewerWithBoxes(image: image)
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                
                                controlsSection
                                    .padding(.horizontal, AppTheme.Spacing.md)
                            } else {
                                emptyStateCard
                                    .padding(.horizontal, AppTheme.Spacing.md)
                                    .padding(.top, AppTheme.Spacing.xl)
                            }
                        }
                        .padding(.vertical, AppTheme.Spacing.md)
                    }
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
            .navigationTitle(loc.t("tab_smart_redact"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            vm.loadSelectedPhoto(data: data)
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Top Action Bar
    
    private var topActionBar: some View {
        HStack(spacing: AppTheme.Spacing.sm) {
            PhotosPicker(selection: $selectedItem, matching: .images) {
                HStack(spacing: AppTheme.Spacing.xs) {
                    VectorIcon(.camera, size: 16, color: AppTheme.textPrimary)
                    Text(vm.originalImage == nil ? loc.t("select_from_library") : loc.t("change_photo"))
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppTheme.textPrimary)
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, 8)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(AppTheme.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.border, lineWidth: 1))
            }
            
            Spacer()
            
            Button {
                vm.loadSampleBill()
            } label: {
                HStack(spacing: AppTheme.Spacing.xs) {
                    VectorIcon(.sparkles, size: 16, color: Color.white)
                    Text(loc.t("load_sample_bill"))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(Color.white)
                }
                .padding(.horizontal, AppTheme.Spacing.sm)
                .padding(.vertical, 8)
                .background(AppTheme.primaryCobalt)
                .cornerRadius(AppTheme.Radius.sm)
            }
        }
    }
    
    // MARK: - Interactive Image Viewer with Bounding Boxes
    
    private func imageViewerWithBoxes(image: UIImage) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
            HStack {
                VectorIcon(.shield, size: 16, color: AppTheme.primaryAccent)
                Text(loc.t("detected_regions"))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text("\(vm.detectedRegions.filter { $0.isRedacted }.count)/\(vm.detectedRegions.count)")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.primaryAccent)
            }
            
            Text(loc.t("tap_hint"))
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.bottom, 4)
            
            GeometryReader { geo in
                let imageSize = image.size
                let aspect = imageSize.width / max(imageSize.height, 1)
                let renderWidth = geo.size.width
                let renderHeight = renderWidth / aspect
                
                ZStack(alignment: .topLeading) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: renderWidth, height: renderHeight)
                        .cornerRadius(AppTheme.Radius.md)
                        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
                    
                    // Render interactive bounding boxes
                    ForEach(vm.detectedRegions) { region in
                        let boxX = region.normalizedRect.origin.x * renderWidth
                        let boxY = region.normalizedRect.origin.y * renderHeight
                        let boxW = region.normalizedRect.width * renderWidth
                        let boxH = region.normalizedRect.height * renderHeight
                        
                        Button {
                            vm.toggleRegion(id: region.id)
                        } label: {
                            ZStack(alignment: .topTrailing) {
                                RoundedRectangle(cornerRadius: 3)
                                    .stroke(region.isRedacted ? AppTheme.primaryAccent : AppTheme.danger, lineWidth: 2)
                                    .background(
                                        (region.isRedacted ? AppTheme.primaryAccent : AppTheme.danger)
                                            .opacity(region.isRedacted ? 0.2 : 0.05)
                                    )
                                
                                // Mini status indicator
                                Circle()
                                    .fill(region.isRedacted ? AppTheme.primaryAccent : AppTheme.danger)
                                    .frame(width: 8, height: 8)
                                    .offset(x: -2, y: 2)
                            }
                            .frame(width: max(boxW, 20), height: max(boxH, 16))
                        }
                        .offset(x: boxX, y: boxY)
                    }
                }
            }
            .frame(height: 380)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    // MARK: - Controls Section
    
    private var controlsSection: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            // Style Selector
            VStack(alignment: .leading, spacing: AppTheme.Spacing.xs) {
                Text(loc.t("default_redact_style"))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                
                HStack(spacing: AppTheme.Spacing.xs) {
                    styleButton(style: .pixelate, titleKey: "style_pixelate")
                    styleButton(style: .blur, titleKey: "style_blur")
                    styleButton(style: .solid, titleKey: "style_solid")
                }
            }
            
            // 1-Tap Toggle Buttons
            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    vm.redactAll()
                } label: {
                    HStack(spacing: 6) {
                        VectorIcon(.eyeOff, size: 16, color: Color.white)
                        Text(loc.t("redact_all"))
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.primaryAccent)
                    .cornerRadius(AppTheme.Radius.sm)
                }
                
                Button {
                    vm.unredactAll()
                } label: {
                    HStack(spacing: 6) {
                        VectorIcon(.sliders, size: 16, color: AppTheme.textPrimary)
                        Text(loc.t("unredact_all"))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(AppTheme.Radius.sm)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.border, lineWidth: 1))
                }
            }
            
            // Action Buttons: Save & Share
            HStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    vm.saveCurrentImageToPhotos()
                } label: {
                    HStack(spacing: 6) {
                        VectorIcon(.download, size: 16, color: Color.white)
                        Text(loc.t("save_image"))
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
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private func styleButton(style: RedactStyle, titleKey: String) -> some View {
        let isSelected = vm.redactStyle == style
        return Button {
            vm.redactStyle = style
        } label: {
            Text(loc.t(titleKey))
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? Color.white : AppTheme.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.primaryCobalt : AppTheme.surfaceElevated)
                .cornerRadius(AppTheme.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(isSelected ? AppTheme.primaryCobalt : AppTheme.border, lineWidth: 1))
        }
    }
    
    // MARK: - Empty State
    
    private var emptyStateCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            VectorIcon(.shield, size: 54, color: AppTheme.primaryAccent, lineWidth: 2.5)
                .padding(.top, AppTheme.Spacing.md)
            
            Text(loc.t("smart_redact_title"))
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(loc.t("smart_redact_subtitle"))
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppTheme.Spacing.md)
            
            VStack(spacing: AppTheme.Spacing.sm) {
                Button {
                    vm.loadSampleBill()
                } label: {
                    HStack(spacing: 8) {
                        VectorIcon(.sparkles, size: 18, color: Color.white)
                        Text(loc.t("load_sample_bill"))
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(Color.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.primaryAccent)
                    .cornerRadius(AppTheme.Radius.md)
                }
                
                PhotosPicker(selection: $selectedItem, matching: .images) {
                    HStack(spacing: 8) {
                        VectorIcon(.camera, size: 18, color: AppTheme.textPrimary)
                        Text(loc.t("select_from_library"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
                }
            }
            .padding(.top, AppTheme.Spacing.sm)
        }
        .padding(AppTheme.Spacing.xl)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.lg).stroke(AppTheme.border, lineWidth: 1))
    }
}
