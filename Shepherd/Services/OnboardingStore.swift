import Foundation
import SwiftData

public enum OnboardingStore {
    public static func complete(
        goal: String,
        experience: String,
        minutes: Int,
        name: String,
        context: ModelContext
    ) {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let chosenName = trimmed.isEmpty ? "Lamb" : trimmed

        let profile = UserProfile(
            goal: goal,
            experienceLevel: experience,
            dailyMinutes: minutes,
            hasCompletedOnboarding: true
        )
        context.insert(profile)

        if let existing = try? context.fetch(FetchDescriptor<Companion>()).first {
            existing.name = chosenName
        } else {
            context.insert(Companion(name: chosenName, stage: 1, xp: 0))
        }

        try? context.save()
    }
}
