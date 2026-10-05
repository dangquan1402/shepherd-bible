import Foundation

public enum Progression {
    public static func xpEarned(score: Int) -> Int {
        return 10 + score
    }

    public static func stage(for xp: Int) -> Int {
        return max(1, min(5, 1 + xp / 50))
    }
}
