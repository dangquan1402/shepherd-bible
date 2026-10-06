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

public struct VerseTimelineProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> VerseEntry {
        VerseEntry(date: .now, verse: DailyVerseService.fallback)
    }

    public func getSnapshot(in context: Context, completion: @escaping (VerseEntry) -> Void) {
        let verse = DailyVerseService.shared.verse()
        completion(VerseEntry(date: .now, verse: verse))
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<VerseEntry>) -> Void) {
        let now = Date.now
        let verse = DailyVerseService.shared.verse(for: now)
        let entry = VerseEntry(date: now, verse: verse)
        let nextMidnight = DailyVerseService.shared.nextMidnight(after: now)
        let timeline = Timeline(entries: [entry], policy: .after(nextMidnight))
        completion(timeline)
    }
}

public struct VerseWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: VerseEntry

    var verse: DailyVerse { entry.verse }

    public init(entry: VerseEntry) {
        self.entry = entry
    }

    public var body: some View {
        Group {
            switch family {
            case .systemMedium:
                mediumView
            default:
                smallView
            }
        }
        .widgetURL(URL(string: "pasture://verse"))
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(ShepherdTheme.goldFill)
                Text("DAILY VERSE")
                    .font(ShepherdTheme.scriptureEyebrow())
                    .foregroundStyle(ShepherdTheme.accent)
            }

            Text(verse.text)
                .font(ShepherdTheme.scriptureBody())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .lineLimit(4)
                .lineSpacing(2)
                .minimumScaleFactor(0.85)

            Spacer(minLength: 0)

            HStack {
                Text(verse.displayRef)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ShepherdTheme.accent)
                Spacer()
                Text("WEB")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(ShepherdTheme.textTertiary)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Daily verse: \(verse.displayRef). \(verse.text). World English Bible.")
    }

    private var mediumView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.goldFill)
                    Text("VERSE OF THE DAY")
                        .font(ShepherdTheme.scriptureEyebrow())
                        .foregroundStyle(ShepherdTheme.accent)
                }
                Spacer()
                Text("World English Bible")
                    .font(.caption2)
                    .foregroundStyle(ShepherdTheme.textTertiary)
            }

            Text(verse.text)
                .font(ShepherdTheme.scriptureBody())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .lineSpacing(3)
                .lineLimit(4)
                .minimumScaleFactor(0.85)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            HStack {
                Text(verse.displayRef)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(ShepherdTheme.accent)
                Spacer()
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verse of the day: \(verse.displayRef). \(verse.text). World English Bible.")
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
