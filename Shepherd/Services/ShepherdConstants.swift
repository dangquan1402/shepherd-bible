import Foundation

public enum ShepherdConstants {
    // MARK: - Product IDs
    public static let monthlySubscriptionID = "com.dangvietquan.shepherd.premium.monthly"
    public static let yearlySubscriptionID = "com.dangvietquan.shepherd.premium.yearly"
    /// App Store Connect's group id; Shepherd.storekit uses the same (`testSubscriptionGroupIDMatchesASCAndStoreKitConfig`).
    public static let subscriptionGroupID = "22442787"

    // MARK: - Premium features other than paths
    // Premium paths are described with counts computed from content (`PremiumOffer`).
    // Only list features that ship and are gated by `Entitlements`.
    public static let premiumFeatures: [String] = [
        "streak freezes"
    ]

    // MARK: - Bible attribution (eBible.org name-use terms: faithful copies only)
    public static let bibleAttribution = "Scripture quotations are from the World English Bible (public domain), unchanged from eBible.org."

    // MARK: - Legal and support URLs (GitHub Pages, dangquan-site repo)
    public static let termsOfServiceURL = URL(string: "https://dangquan1402.github.io/pasture/terms.html")!
    public static let privacyPolicyURL = URL(string: "https://dangquan1402.github.io/pasture/privacy.html")!
    public static let supportURL = URL(string: "https://dangquan1402.github.io/pasture/support.html")!

    public static let legalAndSupportURLs = [termsOfServiceURL, privacyPolicyURL, supportURL]
}
