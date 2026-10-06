import Foundation

public enum ShepherdConstants {
    // MARK: - Product IDs
    public static let monthlySubscriptionID = "com.dangvietquan.shepherd.premium.monthly"
    public static let yearlySubscriptionID = "com.dangvietquan.shepherd.premium.yearly"
    public static let subscriptionGroupID = "21495832"

    // MARK: - Premium features other than paths
    // Premium paths are described with counts computed from content (`PremiumOffer`).
    // Only list features that ship and are gated by `Entitlements`.
    public static let premiumFeatures: [String] = [
        "streak freezes"
    ]

    // MARK: - Bible attribution (eBible.org name-use terms: faithful copies only)
    public static let bibleAttribution = "Scripture quotations are from the World English Bible (public domain), unchanged from eBible.org."

    // MARK: - Legal URLs (TODO: Captain follow-up to provide production URLs)
    // Listed in PR body as follow-up action items.
    public static let termsOfServiceURL = URL(string: "https://shepherd.bible/terms")! // TODO: Replace with production terms URL
    public static let privacyPolicyURL = URL(string: "https://shepherd.bible/privacy")! // TODO: Replace with production privacy URL
}
