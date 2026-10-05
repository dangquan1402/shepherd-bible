import SwiftUI
import SwiftData

public struct MainTabView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var progress: [LessonProgress]
    @State private var selectedTab: Int = 0
    @State private var homeNavPath: [Lesson] = []
    @Namespace private var pathZoomNamespace

    public init() {}

    private var currentLesson: Lesson? {
        guard let path = content.paths.first else { return nil }
        let done = Set(progress.map(\.lessonId))
        return path.lessons.first { !done.contains($0.id) } ?? path.lessons.last
    }

    public var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "sun.max", value: 0) {
                HomeView(
                    navPath: $homeNavPath,
                    namespace: pathZoomNamespace,
                    onSelectLesson: { lesson in
                        homeNavPath.append(lesson)
                    }
                )
            }

            Tab("Bible", systemImage: "book", value: 1) {
                BibleReaderView()
            }

            Tab("Lamb", image: "TabLamb", value: 2) {
                CompanionView()
            }

            Tab("Settings", systemImage: "gearshape", value: 3) {
                SettingsView()
            }
        }
        .tint(ShepherdTheme.accent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .modifier(ConditionalAccessoryModifier(isEnabled: selectedTab == 0 && currentLesson != nil && homeNavPath.isEmpty) {
            if let lesson = currentLesson {
                ContinueLessonAccessory(lesson: lesson) {
                    homeNavPath.append(lesson)
                }
            }
        })
    }
}

private struct ConditionalAccessoryModifier<AccessoryContent: View>: ViewModifier {
    let isEnabled: Bool
    @ViewBuilder let accessory: () -> AccessoryContent

    func body(content: Content) -> some View {
        if #available(iOS 26.1, *) {
            content.tabViewBottomAccessory(isEnabled: isEnabled) {
                accessory()
            }
        } else {
            content.tabViewBottomAccessory {
                accessory()
            }
        }
    }
}
