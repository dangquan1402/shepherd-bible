import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showPaywall: Bool = false
    @State private var restoreToastMessage: String? = nil
    @State private var isRestoring: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                // Subscription Status Section
                Section("Subscription") {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shepherd Premium")
                                .font(.headline)
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Text(store.isPremium ? "Premium Active" : "Not active")
                                .font(.subheadline)
                                .foregroundStyle(store.isPremium ? ShepherdTheme.success : ShepherdTheme.textSecondary)
                        }

                        Spacer()

                        if !store.isPremium {
                            Button("Upgrade") {
                                showPaywall = true
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(ShepherdTheme.accent)
                        } else {
                            Image(systemName: "checkmark.seal.fill")
                                .foregroundStyle(ShepherdTheme.accentFill)
                        }
                    }
                    .padding(.vertical, 4)

                    Button {
                        restore()
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Spacer()
                            if isRestoring {
                                ProgressView()
                            }
                        }
                    }
                }

                // Privacy Section
                Section("Privacy") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("On-device only")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Text("No account. Progress stays on this device.")
                            .font(.footnote)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                    .padding(.vertical, 4)

                    HStack {
                        Text("Ad trackers")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("None in v1")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("App")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("Shepherd")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }

                    HStack {
                        Text("Version")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("1.0 (iOS 26)")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }

                    Link("Terms of Service", destination: ShepherdConstants.termsOfServiceURL)
                        .foregroundStyle(ShepherdTheme.accent)

                    Link("Privacy Policy", destination: ShepherdConstants.privacyPolicyURL)
                        .foregroundStyle(ShepherdTheme.accent)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showPaywall) {
                PaywallView(
                    onContinueFree: { showPaywall = false },
                    onPurchased: { showPaywall = false }
                )
            }
            .overlay(alignment: .bottom) {
                if let message = restoreToastMessage {
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 16))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Text(message)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusPill)
                    .padding(.bottom, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private func restore() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let success = await store.restorePurchases()
            isRestoring = false
            withAnimation {
                restoreToastMessage = success ? "Purchases successfully restored" : "No purchases to restore"
            }
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                restoreToastMessage = nil
            }
        }
    }
}
