import SwiftUI
import WidgetKit

public struct StreakEntry: TimelineEntry {
    public let date: Date
    public let data: WidgetStreakData

    public init(date: Date, data: WidgetStreakData) {
        self.date = date
        self.data = data
    }
}

public struct StreakTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, data: WidgetStreakData(streakCount: 3, isCompletedToday: false, activePathTitle: "First Steps", nextLessonTitle: "In the beginning", nextLessonDayIndex: 4))
    }

    public func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        let data = WidgetDataStore.shared.loadStreakData()
        completion(StreakEntry(date: .now, data: data))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let now = Date.now
        let data = WidgetDataStore.shared.loadStreakData()
        let entry = StreakEntry(date: now, data: data)
        let nextMidnight = DailyVerseService.shared.nextMidnight(after: now)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

public struct StreakWidgetEntryView: View {
    var entry: StreakEntry

    var data: WidgetStreakData { entry.data }

    public init(entry: StreakEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Streak badge
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(ShepherdTheme.goldFill)
                Text("\(data.streakCount)")
                    .font(.title2.weight(.heavy))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                Text(data.streakCount == 1 ? "day" : "days")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.textSecondary)
                Spacer()
            }

            Spacer(minLength: 0)

            // Today's Status
            VStack(alignment: .leading, spacing: 3) {
                if data.isCompletedToday {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ShepherdTheme.accentFill)
                        Text("Today complete")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(ShepherdTheme.accentFill)
                    }
                    Text("Great habit walking!")
                        .font(.caption2)
                        .foregroundStyle(ShepherdTheme.textSecondary)
                } else {
                    let dayNum = data.nextLessonDayIndex ?? 1
                    Text("Day \(dayNum)")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ShepherdTheme.accent)
                    if let title = data.nextLessonTitle, !title.isEmpty {
                        Text(title)
                            .font(.caption2)
                            .foregroundStyle(ShepherdTheme.textSecondary)
                            .lineLimit(1)
                    }
                    Text("Tap to start")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(ShepherdTheme.accentFill)
                        .padding(.top, 2)
                }
            }
        }
        .widgetURL(URL(string: "pasture://lesson"))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            data.isCompletedToday
                ? "\(data.streakCount) day streak. Today's lesson is complete."
                : "\(data.streakCount) day streak. Today's lesson is ready. Tap to start."
        )
    }
}

public struct StreakWidget: Widget {
    public let kind: String = "PastureStreakWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    ShepherdTheme.cardSurface
                }
        }
        .configurationDisplayName("Daily Streak")
        .description("Track your daily Bible habit and progress.")
        .supportedFamilies([.systemSmall])
    }
}
