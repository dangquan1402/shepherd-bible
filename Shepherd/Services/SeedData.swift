import Foundation
import SwiftData

enum SeedData {
    static func ensureDefaults(in context: ModelContext) {
        let companion = try? context.fetch(FetchDescriptor<Companion>())
        if companion?.isEmpty != false {
            context.insert(Companion())
        }
        let streaks = try? context.fetch(FetchDescriptor<StreakState>())
        if streaks?.isEmpty != false {
            context.insert(StreakState())
        }
        let entitlements = try? context.fetch(FetchDescriptor<EntitlementState>())
        if entitlements?.isEmpty != false {
            context.insert(EntitlementState())
        }
        try? context.save()
    }
}
