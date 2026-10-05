import SwiftUI
import SwiftData

public struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var content = ContentStore.shared

    @State private var colorSchemeOverride: ColorScheme? = nil

    public init() {}

    public var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(content)
        .preferredColorScheme(colorSchemeOverride)
        .task {
            #if DEBUG
            handleLaunchArguments()
            #endif
            content.loadIfNeeded()
            SeedData.ensureDefaults(in: modelContext)
        }
    }

    #if DEBUG
    private func handleLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if let idx = args.firstIndex(of: "-appearance"), idx + 1 < args.count {
            let val = args[idx + 1].lowercased()
            if val == "dark" {
                colorSchemeOverride = .dark
            } else if val == "light" {
                colorSchemeOverride = .light
            }
        }
    }
    #endif
}
