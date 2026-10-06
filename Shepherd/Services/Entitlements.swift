import Foundation

/// What Pasture Premium unlocks in this build. Only list things that exist: the paywall copy
/// is derived from these (see `PremiumOffer`, `ShepherdConstants.premiumFeatures`).
public enum PremiumFeature: String, CaseIterable, Sendable {
    /// Lessons of `access: premium` paths beyond their free preview (`PathAccessPolicy`).
    case premiumPaths
    case streakFreezes
}

public enum Entitlements {
    public static func isUnlocked(_ feature: PremiumFeature, isPremium: Bool) -> Bool {
        return isPremium
    }
}
