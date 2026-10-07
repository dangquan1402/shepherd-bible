import SwiftUI
import WidgetKit

public struct VerseEntry: TimelineEntry {
    public let date: Date
    public let verse: DailyVerse

    public init(date: Date, verse: DailyVerse) {
        self.date = date
        self.verse = verse
    }
}

/// One entry for today and one at local midnight with tomorrow's verse.
public struct VerseTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: DailyVerseService.fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        completion(VerseEntry(date: .now, verse: DailyVerseService.shared.verse()))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let entries = WidgetTimeline.entryDates(from: .now).map {
            VerseEntry(date: $0, verse: DailyVerseService.shared.verse(for: $0))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

public struct VerseWidget: Widget {
    public let kind: String = "PastureVerseWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: VerseTimelineProvider()) { entry in
            VerseWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    ShepherdTheme.cardSurface
                }
        }
        .configurationDisplayName("Verse of the Day")
        .description("Daily scripture from the World English Bible.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: VerseEntry

    var body: some View {
        VerseWidgetView(verse: entry.verse, family: family)
    }
}
