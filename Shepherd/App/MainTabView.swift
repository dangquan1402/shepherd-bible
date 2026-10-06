import SwiftUI
import SwiftData

public struct MainTabView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var progress: [LessonProgress]
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: Int = 0
    @State private var homeNavPath: [Lesson] = []
    @Namespace private var pathZoomNamespace

    public init() {}

    /// nil when the active path is complete: the accessory then hides instead of replaying the last day.
    private var currentLesson: Lesson? {
        guard let path = content.activePath(id: profiles.first?.activePathId) else { return nil }
        return PathProgress.nextLesson(in: path, completed: Set(progress.map(\.lessonId)))
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
