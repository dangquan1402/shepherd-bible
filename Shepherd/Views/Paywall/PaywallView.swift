import SwiftUI

struct PaywallView: View {
    var onContinueFree: () -> Void
    var onPurchased: () -> Void
    @StateObject private var store = StoreKitManager.shared

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("🐑").font(.system(size: 64))
                Text("Grow with Shepherd Premium")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                VStack(alignment: .leading, spacing: 10) {
                    label("Full learning paths")
                    label("Streak freezes")
                    label("Companion outfits")
                    label("Widgets & reminders")
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 12) {
                    planCard(title: "Yearly", subtitle: "7-day free trial · Best value", badge: "Most popular")
                    planCard(title: "Monthly", subtitle: "7-day free trial", badge: nil)
                }

                Text("Wire StoreKit product IDs in StoreKitManager + App Store Connect before release.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button("Start free trial") {
                    // Replace with real purchase when products load
                    onPurchased()
                }
                .buttonStyle(.borderedProminent)
                .tint(ShepherdTheme.accent)

                Button("Continue with free path", action: onContinueFree)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(ShepherdTheme.softBackground.ignoresSafeArea())
            .task { await store.loadProducts() }
        }
    }

    private func label(_ text: String) -> some View {
        Label(text, systemImage: "checkmark.circle.fill")
            .foregroundStyle(ShepherdTheme.accent)
    }

    private func planCard(title: String, subtitle: String, badge: String?) -> some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    Text(title).font(.headline)
                    if let badge {
                        Text(badge)
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(ShepherdTheme.mascotYellow)
                            .clipShape(Capsule())
                    }
                }
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding()
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}
