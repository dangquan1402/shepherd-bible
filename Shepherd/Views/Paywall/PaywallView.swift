import SwiftUI
import StoreKit

public struct PaywallView: View {
    public var onContinueFree: () -> Void
    public var onPurchased: () -> Void

    @ObservedObject private var store = StoreKitManager.shared
    @State private var selectedPlanIsYearly: Bool = true
    @Environment(\.dismiss) private var dismiss

    public init(onContinueFree: @escaping () -> Void, onPurchased: @escaping () -> Void) {
        self.onContinueFree = onContinueFree
        self.onPurchased = onPurchased
    }

    private var selectedProduct: Product? {
        selectedPlanIsYearly ? store.yearlyProduct : store.monthlyProduct
    }

    private var yearlyPriceString: String {
        store.yearlyProduct?.displayPrice ?? "$29.99/year"
    }

    private var monthlyPriceString: String {
        store.monthlyProduct?.displayPrice ?? "$4.99/month"
    }

    private var disclosureText: String {
        let price = selectedPlanIsYearly ? "\(yearlyPriceString)" : "\(monthlyPriceString)"
        return "Free for 7 days, then \(price). Auto-renews until cancelled. Cancel anytime in Settings › Apple ID at least 24 hours before the trial ends."
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                ShepherdTheme.canvasBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Mascot Avatar
                        ZStack {
                            Circle()
                                .fill(ShepherdTheme.accentSubtle.opacity(0.4))
                                .frame(width: 90, height: 90)

                            LambAvatarView(stage: 1, expression: .happy, size: 72)
                        }
                        .padding(.top, 12)

                        // Title
                        VStack(spacing: 6) {
                            Text("Grow with Shepherd Premium")
                                .font(ShepherdTheme.title1Serif())
                                .foregroundStyle(ShepherdTheme.textPrimary)
                                .multilineTextAlignment(.center)

                            Text("Deepen your reflection with full access")
                                .font(.subheadline)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }

                        // Feature List (Exactly the 4 from code)
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(ShepherdConstants.premiumFeatures, id: \.self) { feature in
                                HStack(spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 20))
                                        .foregroundStyle(ShepherdTheme.accentFill)

                                    Text(feature)
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundStyle(ShepherdTheme.textPrimary)
                                }
                            }
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ShepherdTheme.cardSurface)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
                        .overlay(
                            RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                                .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
                        )

                        // Plan Cards (Yearly & Monthly)
                        VStack(spacing: 12) {
                            PlanCard(
                                title: "Yearly",
                                subtitle: "7-day free trial · Best value",
                                price: yearlyPriceString,
                                badge: "Most popular",
                                isSelected: selectedPlanIsYearly
                            ) {
                                selectedPlanIsYearly = true
                            }

                            PlanCard(
                                title: "Monthly",
                                subtitle: "7-day free trial",
                                price: monthlyPriceString,
                                badge: nil,
                                isSelected: !selectedPlanIsYearly
                            ) {
                                selectedPlanIsYearly = false
                            }
                        }

                        // Trial Timeline
                        VStack(alignment: .leading, spacing: 12) {
                            timelineRow(
                                day: "Today",
                                title: "7-day free trial starts",
                                subtitle: "Unlock all premium features"
                            )
                            timelineRow(
                                day: "Day 5",
                                title: "Cancel anytime before Day 7",
                                subtitle: "No charges if cancelled"
                            )
                            timelineRow(
                                day: "Day 7",
                                title: "Subscription renews",
                                subtitle: "Auto-renews until cancelled"
                            )
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(ShepherdTheme.surfaceSunken)
                        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))

                        // Legal disclosure
                        Text(disclosureText)
                            .font(.system(size: 12))
                            .foregroundStyle(ShepherdTheme.textTertiary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)

                        // Action Buttons
                        VStack(spacing: 12) {
                            ProminentGlassButton("Start free trial") {
                                startPurchase()
                            }

                            Button("Continue with free path") {
                                onContinueFree()
                                dismiss()
                            }
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                            .padding(.vertical, 6)
                        }
                        .padding(.top, 8)

                        // Footer links
                        HStack(spacing: 16) {
                            Button("Restore Purchases") {
                                restore()
                            }
                            Text("·")
                            Link("Terms of Service", destination: ShepherdConstants.termsOfServiceURL)
                            Text("·")
                            Link("Privacy Policy", destination: ShepherdConstants.privacyPolicyURL)
                        }
                        .font(.caption2)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 20)
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
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(ShepherdTheme.textSecondary)
                            .frame(width: 32, height: 32)
                            .background(ShepherdTheme.surfaceSunken)
                            .clipShape(Circle())
                    }
                }
            }
            .task {
                await store.loadProducts()
            }
        }
    }

    private func timelineRow(day: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(day)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(ShepherdTheme.accent)
                .frame(width: 50, alignment: .leading)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(ShepherdTheme.textSecondary)
            }
        }
    }

    private func startPurchase() {
        if let product = selectedProduct {
            Task {
                let success = await store.purchase(product)
                if success {
                    onPurchased()
                    dismiss()
                }
            }
        } else {
            // Local simulation fallback
            onPurchased()
            dismiss()
        }
    }

    private func restore() {
        Task {
            let success = await store.restorePurchases()
            if success {
                onPurchased()
                dismiss()
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
                    Text(error)
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
