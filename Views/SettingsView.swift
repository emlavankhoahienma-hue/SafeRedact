import SwiftUI

public struct SettingsView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @ObservedObject var vm = RedactWorkspaceViewModel.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: AppTheme.Spacing.md) {
                        // Language Section
                        languageCard
                        
                        // Defaults Section
                        defaultsCard
                        
                        // App Info & Developer
                        appInfoCard
                        
                        // Zero-Cloud Privacy Architecture Card
                        privacyArchitectureCard
                    }
                    .padding(.horizontal, AppTheme.Spacing.md)
                    .padding(.vertical, AppTheme.Spacing.md)
                }
            }
            .navigationTitle(loc.t("tab_settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(AppTheme.surface, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
    
    private var languageCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.sliders, size: 18, color: AppTheme.primaryAccent)
                Text(loc.t("language_section"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            Picker("Language", selection: $loc.language) {
                ForEach(LocalizationManager.Language.allCases) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var defaultsCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.sliders, size: 18, color: AppTheme.primaryCobalt)
                Text(loc.t("defaults_section"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            Toggle(isOn: $vm.autoScrubExifOnSave) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(loc.t("auto_scrub_exif"))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary)
                }
            }
            .tint(AppTheme.primaryAccent)
            .padding(.vertical, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var appInfoCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack {
                VectorIcon(.shield, size: 18, color: AppTheme.primaryAccent)
                Text(loc.t("app_info_section"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            infoRow(label: loc.t("app_name_label"), value: "SafeRedact")
            infoRow(label: loc.t("version_label"), value: "Free")
            infoRow(label: loc.t("developer_label"), value: "ace4youblade")
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private var privacyArchitectureCard: some View {
        VStack(alignment: .leading, spacing: AppTheme.Spacing.sm) {
            HStack(spacing: 8) {
                VectorIcon(.fingerprint, size: 20, color: AppTheme.primaryAccent)
                Text(loc.t("privacy_architecture"))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
            }
            
            Divider().background(AppTheme.border)
            
            Text(loc.t("zero_cloud_guarantee"))
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .lineSpacing(4)
                .padding(.vertical, 4)
        }
        .padding(AppTheme.Spacing.md)
        .background(AppTheme.surface)
        .cornerRadius(AppTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: AppTheme.Radius.md).stroke(AppTheme.border, lineWidth: 1))
    }
    
    private func infoRow(label: String, value: String) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 13, weight: .semibold, design: .monospaced))
                .foregroundColor(AppTheme.textPrimary)
        }
        .padding(.vertical, 2)
    }
}
