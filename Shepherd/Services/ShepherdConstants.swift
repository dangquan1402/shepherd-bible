import Foundation

public enum ShepherdConstants {
    // MARK: - Product IDs
    public static let monthlySubscriptionID = "com.dangvietquan.shepherd.premium.monthly"
    public static let yearlySubscriptionID = "com.dangvietquan.shepherd.premium.yearly"
    public static let subscriptionGroupID = "21495832"

    // MARK: - Premium Features Gated in v1
    public static let premiumFeatures: [String] = [
        "Full learning paths",
        "Streak freezes",
        "Companion outfits",
        "Widgets & reminders"
    ]

    // MARK: - Legal URLs (TODO: Captain follow-up to provide production URLs)
    // Listed in PR body as follow-up action items.
    public static let termsOfServiceURL = URL(string: "https://shepherd.bible/terms")! // TODO: Replace with production terms URL
    public static let privacyPolicyURL = URL(string: "https://shepherd.bible/privacy")! // TODO: Replace with production privacy URL
}
