import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var content: ContentStore
    @Query private var streaks: [StreakState]
    @Query private var companions: [Companion]
    @Query private var progress: [LessonProgress]

    private var streak: StreakState? { streaks.first }
    private var companion: Companion? { companions.first }
    private var nextLesson: Lesson? {
        guard let path = content.paths.first else { return nil }
        let done = Set(progress.map(\.lessonId))
        return path.lessons.first { !done.contains($0.id) } ?? path.lessons.last
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Today")
                                .font(.largeTitle.bold())
                            Text("Streak \(streak?.current ?? 0) 🔥 · Best \(streak?.best ?? 0)")
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text("🐑")
                            .font(.system(size: 40))
                    }

                    if let lesson = nextLesson {
                        NavigationLink {
                            LessonView(lesson: lesson)
                        } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Continue path")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(lesson.title)
                                    .font(.title3.bold())
                                    .foregroundStyle(.primary)
                                Text("Day \(lesson.dayIndex)")
                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                            .background(ShepherdTheme.accent.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }

                    if let name = companion?.name {
                        Text("\(name) is stage \(companion?.stage ?? 1) · \(companion?.xp ?? 0) XP")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding()
            }
            .background(ShepherdTheme.softBackground.ignoresSafeArea())
        }
    }
}
