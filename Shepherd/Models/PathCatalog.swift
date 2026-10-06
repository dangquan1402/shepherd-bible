import Foundation

/// Per-path access, enforced through the Premium entitlement.
public enum PathAccessPolicy {
    /// Free and seasonal paths are always open. A Premium path is open with Premium, and without it
    /// for its first `freePreviewLessons` lessons. Access depends only on content and the
    /// entitlement, never on progress, so a lesson that was free stays free.
    public static func isUnlocked(_ lesson: Lesson, in path: StudyPath, isPremium: Bool) -> Bool {
        switch path.access {
        case .free, .seasonal:
            return true
        case .premium:
            return Entitlements.isUnlocked(.premiumPaths, isPremium: isPremium)
                || lesson.dayIndex <= path.freePreviewLessons
        }
    }

    /// Short label for catalog rows and onboarding: "Free", "Premium · first 3 lessons free".
    public static func label(for path: StudyPath) -> String {
        switch path.access {
        case .free: return "Free"
        case .seasonal: return "Seasonal · Free"
        case .premium:
            switch path.freePreviewLessons {
            case 0: return "Premium"
            case 1: return "Premium · first lesson free"
            default: return "Premium · first \(path.freePreviewLessons) lessons free"
            }
        }
    }
}

public enum PathProgress {
    /// The first lesson not yet completed, or nil when the whole path is done.
    /// (There is deliberately no fallback to the last lesson: a finished path is finished.)
    public static func nextLesson(in path: StudyPath, completed: Set<String>) -> Lesson? {
        path.lessons.first { !completed.contains($0.id) }
    }

    public static func isComplete(_ path: StudyPath, completed: Set<String>) -> Bool {
        !path.lessons.isEmpty && nextLesson(in: path, completed: completed) == nil
    }

    public static func completedCount(in path: StudyPath, completed: Set<String>) -> Int {
        path.lessons.filter { completed.contains($0.id) }.count
    }
}

/// Onboarding answers -> the suggested first path (report §4.3), limited to paths in content.
public enum PathRecommender {
    public static let freeFallbackID = "beginner-30"

    public static func recommendedPathID(goal: String, level: String) -> String {
        switch (goal, level) {
        case ("peace", _): return "peace-14"
        case ("understand", "some"), ("understand", "deep"): return "mark-30"
        case ("grow_daily", "deep"): return "mark-30"
        default: return freeFallbackID
        }
    }

    public static func recommendedPath(goal: String, level: String, in paths: [StudyPath]) -> StudyPath? {
        let id = recommendedPathID(goal: goal, level: level)
        return paths.first { $0.id == id }
            ?? paths.first { $0.id == freeFallbackID }
            ?? paths.sorted { $0.sortOrder < $1.sortOrder }.first
    }
}

/// What Premium adds, counted from the bundled content so the paywall never claims more.
public struct PremiumOffer: Equatable, Sendable {
    public let pathTitles: [String]
    public let lessonCount: Int

    public init(paths: [StudyPath]) {
        let premium = paths.filter { $0.access == .premium }.sorted { $0.sortOrder < $1.sortOrder }
        pathTitles = premium.map(\.title)
        lessonCount = premium.reduce(0) { $0 + $1.lessons.count }
    }

    /// "2 more paths, 6 lessons"; nil when content has no Premium path.
    public var pathsSummary: String? {
        guard !pathTitles.isEmpty else { return nil }
        let paths = pathTitles.count == 1 ? "1 more path" : "\(pathTitles.count) more paths"
        let lessons = lessonCount == 1 ? "1 lesson" : "\(lessonCount) lessons"
        return "\(paths), \(lessons)"
    }

    /// The paywall's "Premium unlocks" line: only features that exist in this build.
    public var unlocksLine: String {
        var items: [String] = []
        if let pathsSummary {
            items.append("\(pathsSummary) (\(pathTitles.joined(separator: "; ")))")
        }
        items.append(contentsOf: ShepherdConstants.premiumFeatures)
        return "Premium unlocks: " + items.joined(separator: ", ")
    }
}
