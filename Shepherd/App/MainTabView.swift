import SwiftUI
import SwiftData

public struct MainTabView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var progress: [LessonProgress]
    @Query private var profiles: [UserProfile]
    @State private var selectedTab: Int = 0
    @State private var homeNavPath: [Lesson] = []
    @State private var bibleTargetVerse: DailyVerse? = nil
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
                    },
                    onSelectVerse: { verse in
                        bibleTargetVerse = verse
                        selectedTab = 1
                    }
                )
            }

            Tab("Bible", systemImage: "book", value: 1) {
                BibleReaderView(targetVerse: $bibleTargetVerse)
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
        .onOpenURL { url in
            handleDeepLink(url)
        }
        .modifier(ConditionalAccessoryModifier(isEnabled: selectedTab == 0 && currentLesson != nil && homeNavPath.isEmpty) {
            if let lesson = currentLesson {
                ContinueLessonAccessory(lesson: lesson) {
                    homeNavPath.append(lesson)
                }
            }
        })
    }

    /// Widget taps: `pasture://verse` opens the reader at today's verse, `pasture://lesson` opens
    /// today's lesson (or just the Today tab when the path is finished).
    private func handleDeepLink(_ url: URL) {
        guard url.scheme == DeepLink.scheme else { return }
        switch url.host {
        case DeepLink.verseHost:
            bibleTargetVerse = DailyVerseService.shared.verse()
            selectedTab = 1
        case DeepLink.lessonHost:
            selectedTab = 0
            if let lesson = currentLesson, homeNavPath.last?.id != lesson.id {
                homeNavPath = [lesson]
            }
        default:
            break
        }
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
