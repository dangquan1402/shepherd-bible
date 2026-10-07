import Foundation

/// A moment at which the app could ask for an App Store rating.
public enum ReviewMoment: Equatable, Sendable {
    case appLaunch
    case paywallDismissed
    /// The user closed the lesson-complete screen.
    case lessonCompleted(dayIndex: Int, score: Int, totalQuestions: Int, oldXP: Int, newXP: Int, wasAlreadyCompleted: Bool)
}

/// When to call StoreKit's `requestReview` (launch research §8.1): after a perfect Day 3 of any
/// path, or when the lamb reaches Stage 2, at most once per app version. Never on launch, never
/// after a wrong answer, never when the paywall is dismissed. There is deliberately no
/// "are you enjoying it?" pre-prompt: Apple asks apps not to filter who sees the rating sheet.
public enum ReviewPromptPolicy {
    public static func shouldRequest(_ moment: ReviewMoment, currentVersion: String, lastPromptedVersion: String?) -> Bool {
        guard case let .lessonCompleted(dayIndex, score, total, oldXP, newXP, wasAlreadyCompleted) = moment else {
            return false // launch, paywall dismissal
        }
        if lastPromptedVersion == currentVersion { return false } // once per version
        if total == 0 || score < total { return false } // a wrong answer in this quiz
        if wasAlreadyCompleted { return false } // a replay earns nothing new
        let reachedStage2 = Progression.stage(for: oldXP) < 2 && Progression.stage(for: newXP) >= 2
        return dayIndex == 3 || reachedStage2
    }
}

public enum ReviewPrompter {
    static let promptedVersionKey = "review.promptedVersion"

    public static var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    /// True when the caller should call `requestReview` now; records the version so the
    /// prompt is not asked for again until the next app version.
    public static func shouldRequest(_ moment: ReviewMoment, defaults: UserDefaults = .standard, version: String = currentVersion) -> Bool {
        let last = defaults.string(forKey: promptedVersionKey)
        guard ReviewPromptPolicy.shouldRequest(moment, currentVersion: version, lastPromptedVersion: last) else {
            return false
        }
        defaults.set(version, forKey: promptedVersionKey)
        return true
    }
}
