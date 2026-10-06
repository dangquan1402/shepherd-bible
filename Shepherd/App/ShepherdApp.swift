import SwiftUI
import SwiftData

@main
struct ShepherdApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [
            UserProfile.self,
            Companion.self,
            StreakState.self,
            LessonProgress.self,
            EntitlementState.self,
            BibleHighlight.self,
            BibleBookmark.self,
            BibleNote.self
        ])
    }
}
