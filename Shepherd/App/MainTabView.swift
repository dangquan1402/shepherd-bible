import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Today", systemImage: "sun.max.fill") }
            PathListView()
                .tabItem { Label("Path", systemImage: "map.fill") }
            CompanionView()
                .tabItem { Label("Lamb", systemImage: "hare.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .tint(ShepherdTheme.accent)
    }
}
