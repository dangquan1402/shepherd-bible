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

/// Reads what the app published to the App Group. The views decide "done today" from each
/// entry's date, so the midnight entry turns a finished day back into a waiting one.
public struct StreakTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> StreakEntry {
        StreakEntry(date: .now, data: WidgetStreakData(streakCount: 3, activePathTitle: "First Steps", nextLessonTitle: "In the beginning", nextLessonDayIndex: 4))
    }

    public func getSnapshot(in context: Context, completion: @escaping (StreakEntry) -> Void) {
        completion(StreakEntry(date: .now, data: WidgetDataStore.shared.loadStreakData()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<StreakEntry>) -> Void) {
        let data = WidgetDataStore.shared.loadStreakData()
        let entries = WidgetTimeline.entryDates(from: .now).map { StreakEntry(date: $0, data: data) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

public struct StreakWidget: Widget {
    public let kind: String = "PastureStreakWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            StreakWidgetView(data: entry.data, date: entry.date)
                .containerBackground(for: .widget) {
                    ShepherdTheme.cardSurface
                }
        }
        .configurationDisplayName("Daily Streak")
        .description("Your streak and today's lesson.")
        .supportedFamilies([.systemSmall])
    }
}
