import SwiftUI

public struct SettingsView: View {
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showPaywall: Bool = false
    @State private var restoreToastMessage: String? = nil
    @State private var isRestoring: Bool = false

    public init() {}

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var body: some View {
        NavigationStack {
            List {
                // Subscription Status Section
                Section("Shepherd Premium") {
                    Button {
                        if !store.isPremium {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Text("Shepherd Premium")
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Spacer()
                            Text(store.isPremium ? "Active" : "Not active ›")
                                .font(.subheadline)
                                .foregroundStyle(store.isPremium ? ShepherdTheme.success : ShepherdTheme.textSecondary)
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        restore()
                    } label: {
                        HStack {
                            Text("Restore Purchases")
                                .foregroundStyle(ShepherdTheme.accentFill)
                            Spacer()
                            if isRestoring {
                                ProgressView()
                            }
                        }
                    }
                }

                // Privacy Section
                Section {
                    HStack {
                        Text("No account")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("On this device")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }

                    HStack {
                        Text("Ad trackers")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("None in v1")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("No account. Progress stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Bible text")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("WEB (public domain)")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }

                    HStack {
                        Text("Version")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text(appVersion)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }

                    Link("Terms of Service", destination: ShepherdConstants.termsOfServiceURL)
                        .foregroundStyle(ShepherdTheme.accentFill)

                    Link("Privacy Policy", destination: ShepherdConstants.privacyPolicyURL)
                        .foregroundStyle(ShepherdTheme.accentFill)
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
                            .font(.subheadline.weight(.medium))
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
