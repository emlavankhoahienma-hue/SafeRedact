import SwiftUI

public struct MetadataScrubberView: View {
    @ObservedObject var vm = RedactWorkspaceViewModel.shared
    @ObservedObject var loc = LocalizationManager.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Header Banner
                        headerBanner
                        
                        if let report = vm.metadataReport {
                            // GPS Card
                            gpsCard(report: report)
                            
                            // Device Card
                            deviceCard(report: report)
                            
                            // Capture Parameters Card
                            captureCard(report: report)
                            
                            // Scrub All Action Button
                            scrubActionButton
                        } else {
                            noReportCard
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
            .navigationTitle(loc.t("tab_exif_scrubber"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                VectorIcon(.eyeOff, size: 20, color: AppTheme.primaryAccent)
                Text(loc.t("exif_title"))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if let report = vm.metadataReport {
                    Text("\(report.rawPropertiesCount) tags")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(report.hasSensitiveMetadata ? AppTheme.danger.opacity(0.2) : AppTheme.primaryAccent.opacity(0.2))
                        .foregroundColor(report.hasSensitiveMetadata ? AppTheme.danger : AppTheme.primaryAccent)
                        .cornerRadius(6)
                }
            }
            Text(loc.t("exif_subtitle"))
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private func gpsCard(report: ExifMetadataReport) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.crosshairScan, size: 18, color: report.hasGPS ? AppTheme.danger : AppTheme.primaryAccent)
                Text(loc.t("gps_location"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Text(report.hasGPS ? "LEAKED" : "CLEAN")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(report.hasGPS ? AppTheme.danger.opacity(0.15) : AppTheme.primaryAccent.opacity(0.15))
                    .foregroundColor(report.hasGPS ? AppTheme.danger : AppTheme.primaryAccent)
                    .cornerRadius(4)
            }
            
            Divider().background(AppTheme.border)
            
            if report.hasGPS, let lat = report.latitude, let lon = report.longitude {
                metadataRow(label: loc.t("latitude"), value: String(format: "%.6f", lat), isMonospaced: true)
                metadataRow(label: loc.t("longitude"), value: String(format: "%.6f", lon), isMonospaced: true)
                if let alt = report.altitude {
                    metadataRow(label: loc.t("altitude"), value: String(format: "%.1f m", alt), isMonospaced: true)
                }
            } else {
                Text(loc.t("no_gps_leaks"))
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .padding(.vertical, 4)
            }
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private func deviceCard(report: ExifMetadataReport) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.camera, size: 18, color: AppTheme.primaryCobalt)
                Text(loc.t("device_info"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            metadataRow(label: loc.t("make"), value: report.cameraMake ?? "--")
            metadataRow(label: loc.t("model"), value: report.cameraModel ?? "--")
            metadataRow(label: loc.t("lens"), value: report.lensModel ?? "--")
            metadataRow(label: loc.t("software"), value: report.software ?? "--")
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private func captureCard(report: ExifMetadataReport) -> some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.sliders, size: 18, color: AppTheme.primaryAccent)
                Text(loc.t("capture_details"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            metadataRow(label: loc.t("datetime"), value: report.dateTimeOriginal ?? "--")
            metadataRow(label: loc.t("iso"), value: report.iso != nil ? "\(report.iso!)" : "--", isMonospaced: true)
            metadataRow(label: loc.t("focal_length"), value: report.focalLength != nil ? String(format: "%.1f mm", report.focalLength!) : "--", isMonospaced: true)
            metadataRow(label: loc.t("exposure"), value: report.exposureTime != nil ? String(format: "1/%.0f s", 1.0 / report.exposureTime!) : "--", isMonospaced: true)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var scrubActionButton: some View {
        Button {
            _ = vm.scrubAllMetadataAndSave()
        } label: {
            HStack(spacing: 8) {
                VectorIcon(.trash, size: 18, color: Color.white)
                Text(loc.t("scrub_action"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(AppTheme.primaryAccent)
            .cornerRadius(AppTheme.Radius.md)
        }
    }
    
    private var noReportCard: some View {
        VStack(spacing: AppTheme.Spacing.md) {
            VectorIcon(.eyeOff, size: 48, color: AppTheme.textSecondary)
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
    
    private func metadataRow(label: String, value: String, isMonospaced: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(isMonospaced ? .system(size: 13, weight: .semibold, design: .monospaced) : .system(size: 13, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, 2)
    }
}
