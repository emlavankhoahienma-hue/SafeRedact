import SwiftUI

public struct MainTabView: View {
    @ObservedObject var loc = LocalizationManager.shared
    @State private var selectedTab: Int = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            SmartRedactView()
                .tabItem {
                    Label {
                        Text(loc.t("tab_smart_redact"))
                    } icon: {
                        Image(systemName: "shield.lefthalf.filled")
                    }
                }
                .tag(0)
            
            MetadataScrubberView()
                .tabItem {
                    Label {
                        Text(loc.t("tab_exif_scrubber"))
                    } icon: {
                        Image(systemName: "eye.slash")
                    }
                }
                .tag(1)
            
            WatermarkStudioView()
                .tabItem {
                    Label {
                        Text(loc.t("tab_watermark"))
                    } icon: {
                        Image(systemName: "lock.doc")
                    }
                }
                .tag(2)
            
            SettingsView()
                .tabItem {
                    Label {
                        Text(loc.t("tab_settings"))
                    } icon: {
                        Image(systemName: "slider.horizontal.3")
                    }
                }
                .tag(3)
        }
        .tint(AppTheme.primaryAccent)
        .preferredColorScheme(.dark)
    }
}
