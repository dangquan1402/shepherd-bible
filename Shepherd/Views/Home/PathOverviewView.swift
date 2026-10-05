import SwiftUI

public struct PathOverviewView: View {
    @EnvironmentObject private var content: ContentStore

    public init() {}

    public var body: some View {
        List {
            Section("Current Path") {
                if let path = content.paths.first {
                    NavigationLink {
                        PathLessonsListView(path: path)
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(path.title)
                                    .font(.headline)
                                    .foregroundStyle(ShepherdTheme.textPrimary)
                                Spacer()
                                Text("\(path.estimatedDays) Days")
                                    .font(.subheadline)
                                    .foregroundStyle(ShepherdTheme.accent)
                            }
                            Text("Level: \(path.level.capitalized) · 7 lessons")
                                .font(.footnote)
                                .foregroundStyle(ShepherdTheme.textSecondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }

            Section {
                // Captain Decision D2: Exactly one honest "More paths are coming" row
                HStack(spacing: 12) {
                    Image(systemName: "hourglass")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("More paths are coming")
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                        Text("New devotional paths will be added in future updates.")
                            .font(.footnote)
                            .foregroundStyle(ShepherdTheme.textTertiary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle("Paths")
        .navigationBarTitleDisplayMode(.large)
    }
}

public struct PathLessonsListView: View {
    public let path: StudyPath
    @EnvironmentObject private var content: ContentStore

    public init(path: StudyPath) {
        self.path = path
    }

    public var body: some View {
        List(path.lessons) { lesson in
            NavigationLink {
                LessonView(lesson: lesson)
            } label: {
                HStack(spacing: 14) {
                    Text("Day \(lesson.dayIndex)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ShepherdTheme.accent)
                        .frame(width: 48, alignment: .leading)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(lesson.title)
                            .font(.headline)
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        Text(lesson.verseRefs.joined(separator: ", "))
                            .font(.caption)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .navigationTitle(path.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
