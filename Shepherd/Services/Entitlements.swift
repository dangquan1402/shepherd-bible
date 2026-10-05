import Foundation

public enum PremiumFeature: String, CaseIterable, Sendable {
    case fullPaths
    case streakFreezes
    case companionOutfits
    case widgetsReminders
}

public enum Entitlements {
    public static func isUnlocked(_ feature: PremiumFeature, isPremium: Bool) -> Bool {
        return isPremium
    }
}
