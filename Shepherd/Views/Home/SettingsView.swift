import SwiftUI
import SwiftData

public struct SettingsView: View {
    @ObservedObject private var store = StoreKitManager.shared
    @ObservedObject private var reminder = DailyReminder.shared
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.openURL) private var openURL
    @Query private var entitlements: [EntitlementState]
    /// Notifications are off for Pasture in iOS Settings.
    @State private var notificationsDenied: Bool = false
    /// The user asked for the reminder, and iOS said no (now or earlier).
    @State private var reminderRefused: Bool = false
    @State private var showPaywall: Bool = false
    @State private var restoreToastMessage: String? = nil
    @State private var isRestoring: Bool = false

    public init() {}

    private var isPremiumActive: Bool {
        store.isPremium || entitlements.first?.isPremium == true
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    public var body: some View {
        NavigationStack {
            List {
                // Subscription Status Section
                Section("Pasture Premium") {
                    Button {
                        if !isPremiumActive {
                            showPaywall = true
                        }
                    } label: {
                        HStack {
                            Text("Pasture Premium")
                                .foregroundStyle(ShepherdTheme.textPrimary)
                            Spacer()
                            Text(isPremiumActive ? "Active" : "Not active ›")
                                .font(.subheadline)
                                .foregroundStyle(isPremiumActive ? ShepherdTheme.success : ShepherdTheme.textSecondary)
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
                .listRowBackground(ShepherdTheme.cardSurface)

                // Daily reminder (local notification, opt-in)
                Section {
                    Toggle(isOn: reminderBinding) {
                        Text("Daily reminder")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                    }
                    .tint(ShepherdTheme.accentFill)

                    if reminder.settings.isEnabled {
                        DatePicker(selection: reminderTimeBinding, displayedComponents: .hourAndMinute) {
                            Text("Time")
                                .foregroundStyle(ShepherdTheme.textPrimary)
                        }
                    }

                    if notificationsDenied && (reminder.settings.isEnabled || reminderRefused) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Notifications are off for Pasture, so the reminder can’t appear. You can allow them in the Settings app.")
                                .font(.subheadline)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                            Button("Open Settings") {
                                if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                                    openURL(url)
                                }
                            }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.accentFill)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Reminder")
                } footer: {
                    Text("One gentle notification a day, skipped once you’ve done that day’s lesson. It’s scheduled on this device; nothing is sent anywhere.")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .listRowBackground(ShepherdTheme.cardSurface)

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
                        Text("None")
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("No account. Progress stays on this device.")
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .listRowBackground(ShepherdTheme.cardSurface)

                // About Section
                Section {
                    HStack {
                        Text("Bible text")
                            .foregroundStyle(ShepherdTheme.textPrimary)
                        Spacer()
                        Text("World English Bible")
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

                    Link("Help & Support", destination: ShepherdConstants.supportURL)
                        .foregroundStyle(ShepherdTheme.accentFill)
                } header: {
                    Text("About")
                } footer: {
                    Text(ShepherdConstants.bibleAttribution)
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .listRowBackground(ShepherdTheme.cardSurface)
            }
            .scrollContentBackground(.hidden)
            .background(ShepherdTheme.canvasBg.ignoresSafeArea())
            .navigationTitle("Settings")
            .task { await refreshNotificationStatus() }
            .onChange(of: scenePhase) { _, phase in
                // Back from the Settings app: notifications may have been allowed.
                if phase == .active {
                    Task { await refreshNotificationStatus() }
                }
            }
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

    private var completedToday: Bool {
        DailyReminder.hasCompletedLesson(on: .now, in: modelContext)
    }

    private var reminderBinding: Binding<Bool> {
        Binding(
            get: { reminder.settings.isEnabled },
            set: { isOn in
                Task {
                    if isOn {
                        let result = await reminder.enable(completedToday: completedToday)
                        reminderRefused = (result == .denied)
                    } else {
                        reminderRefused = false
                        await reminder.disable()
                    }
                    await refreshNotificationStatus()
                }
            }
        )
    }

    private var reminderTimeBinding: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(bySettingHour: reminder.settings.hour, minute: reminder.settings.minute, second: 0, of: .now) ?? .now
            },
            set: { date in
                let parts = Calendar.current.dateComponents([.hour, .minute], from: date)
                Task {
                    await reminder.setTime(hour: parts.hour ?? 8, minute: parts.minute ?? 0, completedToday: completedToday)
                }
            }
        )
    }

    private func refreshNotificationStatus() async {
        notificationsDenied = await reminder.authorizationStatus() == .denied
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
