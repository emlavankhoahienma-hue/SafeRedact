import SwiftUI
import PhotosUI

public struct SmartRedactView: View {
    @ObservedObject var vm = RedactWorkspaceViewModel.shared
    @ObservedObject var loc = LocalizationManager.shared
    
    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var showShareSheet: Bool = false
    @State private var showScannerSheet: Bool = false
    
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
                    
                    // Batch Processing Banner
                    if vm.isBatchProcessing {
                        batchProgressBanner
                    }
                    
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
            .sheet(isPresented: $showScannerSheet) {
                LibraryScannerSheetView(vm: vm, loc: loc)
            }
            .onChange(of: selectedItems) { newItems in
                handleSelectedItems(newItems)
            }
        }
    }
    
    // MARK: - Handle Single or Batch Photo Pick
    
    private func handleSelectedItems(_ items: [PhotosPickerItem]) {
        guard !items.isEmpty else { return }
        
        if items.count == 1 {
            Task {
                if let data = try? await items.first?.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        vm.loadSelectedPhoto(data: data)
                    }
                }
            }
        } else {
            // Batch Multi-Photo Processing (Multi-threaded TaskGroup)
            Task {
                var dataList: [Data] = []
                for item in items {
                    if let data = try? await item.loadTransferable(type: Data.self) {
                        dataList.append(data)
                    }
                }
                await vm.processBatchPhotos(dataList: dataList)
            }
        }
    }
    
    // MARK: - Top Action Bar
    
    private var topActionBar: some View {
        HStack(spacing: AppTheme.Spacing.xs) {
            PhotosPicker(selection: $selectedItems, maxSelectionCount: 30, matching: .images) {
                HStack(spacing: 4) {
                    VectorIcon(.camera, size: 14, color: AppTheme.textPrimary)
                    Text(vm.originalImage == nil ? loc.t("select_from_library") : loc.t("change_photo_short"))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(AppTheme.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(AppTheme.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.border, lineWidth: 1))
            }
            
            Button {
                showScannerSheet = true
            } label: {
                HStack(spacing: 4) {
                    VectorIcon(.crosshairScan, size: 14, color: AppTheme.primaryAccent)
                    Text(loc.t("scan_library_short"))
                        .font(.system(size: 12, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(AppTheme.primaryAccent)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(AppTheme.surfaceElevated)
                .cornerRadius(AppTheme.Radius.sm)
                .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.sm).stroke(AppTheme.primaryAccent.opacity(0.4), lineWidth: 1))
            }
            
            Button {
                vm.loadSampleBill()
            } label: {
                HStack(spacing: 4) {
                    VectorIcon(.sparkles, size: 14, color: Color.white)
                    Text(loc.t("load_sample_short"))
                        .font(.system(size: 12, weight: .bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .foregroundColor(Color.white)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(AppTheme.primaryCobalt)
                .cornerRadius(AppTheme.Radius.sm)
            }
        }
    }
    
    // MARK: - Batch Progress Banner
    
    private var batchProgressBanner: some View {
        VStack(spacing: 6) {
            HStack {
                VectorIcon(.sliders, size: 16, color: AppTheme.primaryAccent)
                Text("\(loc.t("batch_progress")): \(vm.batchProcessedCount)/\(vm.batchTotalCount)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(String(format: "%.0f%%", vm.batchProgress * 100))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(AppTheme.primaryAccent)
            }
            ProgressView(value: vm.batchProgress)
                .tint(AppTheme.primaryAccent)
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.sm)
        .background(AppTheme.surfaceElevated)
        .overlay(Rectangle().frame(height: 1).foregroundColor(AppTheme.border), alignment: .bottom)
    }
    
    // MARK: - Interactive Image Viewer with Tap to Toggle/Unredact
    
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
                let containerWidth = geo.size.width
                let containerHeight = geo.size.height
                let imgW = max(image.size.width, 1)
                let imgH = max(image.size.height, 1)
                let imageAspect = imgW / imgH
                let containerAspect = containerWidth / max(containerHeight, 1)
                
                let renderWidth: CGFloat
                let renderHeight: CGFloat
                if imageAspect > containerAspect {
                    renderWidth = containerWidth
                    renderHeight = containerWidth / imageAspect
                } else {
                    renderHeight = containerHeight
                    renderWidth = containerHeight * imageAspect
                }
                
                let offsetX = (containerWidth - renderWidth) / 2
                let offsetY = (containerHeight - renderHeight) / 2
                
                ZStack(alignment: .topLeading) {
                    Color.clear
                        .frame(width: containerWidth, height: containerHeight)
                    
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(width: renderWidth, height: renderHeight)
                        .cornerRadius(AppTheme.Radius.md)
                        .offset(x: offsetX, y: offsetY)
                    
                    // Interactive Bounding Boxes: Tap to Toggle Redact / Unredact
                    ForEach(vm.detectedRegions) { region in
                        let boxX = offsetX + region.normalizedRect.origin.x * renderWidth
                        let boxY = offsetY + region.normalizedRect.origin.y * renderHeight
                        let boxW = max(region.normalizedRect.width * renderWidth, 24)
                        let boxH = max(region.normalizedRect.height * renderHeight, 18)
                        
                        Button {
                            vm.toggleRegion(id: region.id)
                        } label: {
                            ZStack(alignment: .topLeading) {
                                if region.isRedacted {
                                    // Redacted State: Solid / Blurred frame
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(region.type.badgeColor.opacity(0.25))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(region.type.badgeColor, lineWidth: 2)
                                        )
                                } else {
                                    // Unredacted State: Dashed border outline
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(
                                            Color.white.opacity(0.8),
                                            style: StrokeStyle(lineWidth: 1.5, dash: [4])
                                        )
                                        .background(Color.black.opacity(0.1))
                                }
                                
                                // Mini Badge
                                Text(region.type.rawValue.uppercased())
                                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                                    .padding(.horizontal, 3)
                                    .padding(.vertical, 1)
                                    .background(region.isRedacted ? region.type.badgeColor : Color.gray.opacity(0.8))
                                    .foregroundColor(Color.white)
                                    .cornerRadius(2)
                                    .offset(x: 2, y: -8)
                            }
                            .frame(width: boxW, height: boxH)
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
            
            // Action Buttons: Save & Share (100% Full-Resolution)
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
                
                PhotosPicker(selection: $selectedItems, maxSelectionCount: 30, matching: .images) {
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
                
                Button {
                    showScannerSheet = true
                } label: {
                    HStack(spacing: 8) {
                        VectorIcon(.crosshairScan, size: 18, color: AppTheme.primaryCobalt)
                        Text(loc.t("scan_library_btn"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(AppTheme.primaryCobalt)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppTheme.surfaceElevated)
                    .cornerRadius(AppTheme.Radius.md)
                    .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.primaryCobalt.opacity(0.4), lineWidth: 1))
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

// MARK: - Library Scanner Sheet View

public struct LibraryScannerSheetView: View {
    @ObservedObject var vm: RedactWorkspaceViewModel
    @ObservedObject var loc: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: AppTheme.Spacing.md) {
                    if vm.isScanningLibrary {
                        VStack(spacing: 12) {
                            ProgressView(value: vm.scanProgress)
                                .tint(AppTheme.primaryAccent)
                            Text(loc.t("scan_in_progress"))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .padding(AppTheme.Spacing.xl)
                    } else if vm.flaggedPhotos.isEmpty {
                        VStack(spacing: AppTheme.Spacing.md) {
                            VectorIcon(.shield, size: 48, color: AppTheme.primaryAccent)
                            Text(loc.t("safe_library_notice"))
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.textPrimary)
                            Button {
                                Task {
                                    await vm.runLibraryPrivacyScan()
                                }
                            } label: {
                                Text(loc.t("scan_library_btn"))
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color.white)
                                    .padding(.horizontal, AppTheme.Spacing.lg)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.primaryAccent)
                                    .cornerRadius(AppTheme.Radius.sm)
                            }
                        }
                        .padding(AppTheme.Spacing.xl)
                    } else {
                        List {
                            ForEach(vm.flaggedPhotos) { item in
                                Button {
                                    vm.selectFlaggedPhoto(item: item)
                                    dismiss()
                                } label: {
                                    HStack(spacing: AppTheme.Spacing.sm) {
                                        VectorIcon(iconForCategory(item.category), size: 20, color: colorForCategory(item.category))
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(item.title)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(AppTheme.textPrimary)
                                            Text(item.subtitle)
                                                .font(.system(size: 12))
                                                .foregroundColor(AppTheme.textSecondary)
                                        }
                                        Spacer()
                                        VectorIcon(.download, size: 14, color: AppTheme.textSecondary)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(AppTheme.surface)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .padding(.top, AppTheme.Spacing.md)
            }
            .navigationTitle(loc.t("scan_library_title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(AppTheme.textSecondary)
                }
            }
            .task {
                if vm.flaggedPhotos.isEmpty && !vm.isScanningLibrary {
                    await vm.runLibraryPrivacyScan()
                }
            }
        }
    }
    
    private func iconForCategory(_ category: FlaggedCategory) -> VectorIcon.IconKind {
        switch category {
        case .documentCard: return .fileLock
        case .personalPII: return .qrCode
        case .gpsLeak: return .crosshairScan
        }
    }
    
    private func colorForCategory(_ category: FlaggedCategory) -> Color {
        switch category {
        case .documentCard: return AppTheme.warning
        case .personalPII: return AppTheme.danger
        case .gpsLeak: return AppTheme.primaryAccent
        }
    }
}
