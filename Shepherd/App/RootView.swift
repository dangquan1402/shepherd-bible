import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @StateObject private var content = ContentStore.shared

    var body: some View {
        Group {
            if profiles.isEmpty {
                OnboardingFlowView()
            } else {
                MainTabView()
            }
        }
        .environmentObject(content)
        .task {
            content.loadIfNeeded()
            SeedData.ensureDefaults(in: modelContext)
        }
    }
}
