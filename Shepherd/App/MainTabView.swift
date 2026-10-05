import SwiftUI
import SwiftData

public struct MainTabView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var progress: [LessonProgress]
    @State private var selectedTab: Int = 0
    @State private var pushedLesson: Lesson? = nil

    public init() {}

    private var currentLesson: Lesson? {
        guard let path = content.paths.first else { return nil }
        let done = Set(progress.map(\.lessonId))
        return path.lessons.first { !done.contains($0.id) } ?? path.lessons.last
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "sun.max", value: 0) {
                HomeView(onSelectLesson: { lesson in
                    pushedLesson = lesson
                })
            }

            Tab("Bible", systemImage: "book", value: 1) {
                BibleReaderView()
            }

            Tab(value: 2) {
                CompanionView()
            } label: {
                Label {
                    Text("Lamb")
                } icon: {
                    LambGlyph(size: 24)
                }
            }

            Tab("Settings", systemImage: "gearshape", value: 3) {
                SettingsView()
            }
        }
        .tint(ShepherdTheme.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if let lesson = currentLesson, selectedTab == 0 {
                ContinueLessonAccessory(lesson: lesson) {
                    pushedLesson = lesson
                }
            }
        }
        .sheet(item: $pushedLesson) { lesson in
            NavigationStack {
                LessonView(lesson: lesson)
            }
        }
    }
}
