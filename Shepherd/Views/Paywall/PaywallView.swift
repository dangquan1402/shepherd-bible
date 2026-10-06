import SwiftUI
import StoreKit

public struct PaywallView: View {
    /// The Day 5 "Cancel anytime before Day 7" row. Not a bell: the app sends no trial reminder.
    static let day5Icon = "calendar"

    public var onContinueFree: () -> Void
    public var onPurchased: () -> Void

    @ObservedObject private var store = StoreKitManager.shared
    @ObservedObject private var content = ContentStore.shared
    @State private var selectedPlanIsYearly: Bool = true
    @State private var restoreToastMessage: String? = nil
    @State private var isRestoring: Bool = false
    @Environment(\.dismiss) private var dismiss

    public init(onContinueFree: @escaping () -> Void, onPurchased: @escaping () -> Void) {
        self.onContinueFree = onContinueFree
        self.onPurchased = onPurchased
    }

    private var selectedProduct: Product? {
        selectedPlanIsYearly ? store.yearlyProduct : store.monthlyProduct
    }

    private var pricePeriodString: String? {
        guard let p = selectedProduct else { return nil }
        let period = selectedPlanIsYearly ? "year" : "month"
        return "\(p.displayPrice)/\(period)"
    }

    private var disclosureText: String {
        if let price = pricePeriodString {
            return "Free for 7 days, then \(price). Auto-renews until cancelled. Cancel anytime in Settings › Apple ID at least 24 hours before the trial ends."
        } else {
            return "Free for 7 days, then subscription starts unless cancelled. Auto-renews until cancelled. Cancel anytime in Settings › Apple ID at least 24 hours before the trial ends."
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header with Title and Mascot Avatar
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 12) {
                                BrandLockup(.compact)
                                Text("Start your 7-day free trial")
                                    .font(ShepherdTheme.title1Serif())
                                    .foregroundStyle(ShepherdTheme.textPrimary)
                            }
                            Spacer()
                            LambAvatarView(stage: 1, expression: .happy, size: 72)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 16)

                        // Timeline Rows per spec
                        VStack(spacing: 14) {
                            timelineRow(
                                icon: "checkmark.circle.fill",
                                iconColor: ShepherdTheme.accentFill,
                                title: "Set your daily goal",
                                subtitle: "Done"
                            )
                            timelineRow(
                                icon: "lock.open.fill",
                                iconColor: ShepherdTheme.accentFill,
                                title: "Today",
                                subtitle: PremiumOffer(paths: content.paths).unlocksLine
                            )
                            timelineRow(
                                icon: Self.day5Icon,
                                iconColor: ShepherdTheme.textSecondary,
                                title: "Day 5",
                                subtitle: "Cancel anytime before Day 7"
                            )
                            timelineRow(
                                icon: "star.fill",
                                iconColor: ShepherdTheme.accentFill,
                                title: "Day 7",
                                subtitle: store.yearlyProduct != nil
                                    ? "Trial ends; \(store.yearlyProduct!.displayPrice)/year starts unless you cancel"
                                    : "Trial ends; subscription starts unless you cancel"
                            )
                        }
                        .padding(18)
                        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusLG)
                        .padding(.horizontal, 20)

                        // Plan Selector
                        if store.products.isEmpty {
                            VStack(spacing: 12) {
                                if store.lastErrorMessage != nil {
                                    Text("Couldn't load prices")
                                        .font(.subheadline)
                                        .foregroundStyle(ShepherdTheme.textSecondary)
                                    SecondaryGlassButton("Retry") {
                                        Task { await store.loadProducts() }
                                    }
                                } else {
                                    ProgressView()
                                        .padding(.vertical, 20)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 20)
                        } else {
                            VStack(spacing: 12) {
                                if let yearly = store.yearlyProduct {
                                    planCard(
                                        title: "Annual · 7-day trial",
                                        price: "\(yearly.displayPrice)/year",
                                        badge: "Save 50%",
                                        isSelected: selectedPlanIsYearly
                                    ) {
                                        selectedPlanIsYearly = true
                                    }
                                }

                                if let monthly = store.monthlyProduct {
                                    planCard(
                                        title: "Monthly · 7-day trial",
                                        price: "\(monthly.displayPrice)/month",
                                        badge: nil,
                                        isSelected: !selectedPlanIsYearly
                                    ) {
                                        selectedPlanIsYearly = false
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }

                        // Disclosure Text
                        Text(disclosureText)
                            .font(.footnote)
                            .foregroundStyle(ShepherdTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)

                        // CTA Buttons
                        VStack(spacing: 12) {
                            ProminentGlassButton(selectedProduct == nil ? "Loading…" : "Start free trial") {
                                startPurchase()
                            }
                            .disabled(selectedProduct == nil)

                            Button("Continue with free path") {
                                onContinueFree()
                                dismiss()
                            }
                            .font(.body.weight(.medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                        .padding(.horizontal, 20)

                        // Legal Footer
                        HStack(spacing: 8) {
                            Button("Restore Purchases") {
                                restore()
                            }
                            Text("·")
                            Link("Terms", destination: ShepherdConstants.termsOfServiceURL)
                            Text("·")
                            Link("Privacy", destination: ShepherdConstants.privacyPolicyURL)
                        }
                        .font(.footnote)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                        .padding(.bottom, 24)
                    }
                }

                // Overlay dialogs for purchasing states
                if store.purchaseState != .idle {
                    paywallStateOverlay
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onContinueFree()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                }
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
            .onAppear {
                store.purchaseState = .idle
                if store.products.isEmpty {
                    Task {
                        await store.loadProducts()
                    }
                }
            }
        }
    }

    private func timelineRow(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(iconColor)
                .frame(width: 24, height: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.textPrimary)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
    }

    private func planCard(title: String, price: String, badge: String?, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        if let badge = badge {
                            Text(badge)
                                .font(.caption.bold())
                                .foregroundStyle(ShepherdTheme.accentFill)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(ShepherdTheme.accentSubtle)
                                .clipShape(Capsule())
                        }
                    }

                    Text(price)
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }

                Spacer()

                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? ShepherdTheme.accentFill : ShepherdTheme.textTertiary)
            }
            .padding(16)
            .background(isSelected ? ShepherdTheme.accentSubtle.opacity(0.3) : ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(isSelected ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func startPurchase() {
        guard let product = selectedProduct else { return }
        Task {
            let success = await store.purchase(product)
            if success {
                onPurchased()
                dismiss()
            }
        }
    }

    private func restore() {
        guard !isRestoring else { return }
        isRestoring = true
        Task {
            let success = await store.restorePurchases()
            isRestoring = false
            if !success {
                withAnimation {
                    restoreToastMessage = "No purchases to restore"
                }
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                withAnimation {
                    restoreToastMessage = nil
                }
            }
        }
    }

    @ViewBuilder
    private var paywallStateOverlay: some View {
        ZStack {
            ShepherdTheme.scrim.ignoresSafeArea()

            VStack(spacing: 16) {
                switch store.purchaseState {
                case .purchasing:
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Connecting to App Store…")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)

                case .pending:
                    Image(systemName: "hourglass")
                        .font(.system(size: 32))
                        .foregroundStyle(ShepherdTheme.accentFill)
                    Text("Waiting for approval")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    Text("Ask to Buy approval is required.")
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                    SecondaryGlassButton("Dismiss") {
                        store.purchaseState = .idle
                    }

                case .failed(let error):
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ShepherdTheme.error)
                    Text("Purchase didn't go through")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    Text("You haven't been charged. \(error)")
                        .font(.subheadline)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                        .multilineTextAlignment(.center)
                    HStack(spacing: 12) {
                        SecondaryGlassButton("Not now") {
                            store.purchaseState = .idle
                        }
                        ProminentGlassButton("Try again") {
                            store.purchaseState = .idle
                            startPurchase()
                        }
                    }

                case .restored:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                        .foregroundStyle(ShepherdTheme.success)
                    Text("Purchases Restored")
                        .font(.headline)
                        .foregroundStyle(ShepherdTheme.textPrimary)
                    ProminentGlassButton("Continue") {
                        store.purchaseState = .idle
                        onPurchased()
                        dismiss()
                    }

                case .idle:
                    EmptyView()
                }
            }
            .padding(24)
            .frame(maxWidth: 320)
            .shepherdGlassCard(cornerRadius: 24)
        }
    }
}
