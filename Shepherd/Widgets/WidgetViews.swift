import SwiftUI
import WidgetKit

// Widget content views. Compiled into the ShepherdWidgets extension (which wraps them in
// StaticConfigurations) and into the app, so unit tests can render them off-screen. The family
// and the entry date are parameters, not environment, for the same reason.

/// Verse of the day: the whole verse, its reference and "World English Bible".
/// The text steps down through serif sizes until the verse fits (curated verses are at most
/// 150 characters, enforced by tools/content/validate_content.py).
public struct VerseWidgetView: View {
    public let verse: DailyVerse
    public let family: WidgetFamily

    public init(verse: DailyVerse, family: WidgetFamily) {
        self.verse = verse
        self.family = family
    }

    public var body: some View {
        Group {
            if family == .systemMedium {
                medium
            } else {
                small
            }
        }
        .widgetURL(DeepLink.verse)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verse of the day. \(verse.spokenLabel)")
    }

    private var small: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: "sun.max.fill")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.streak)
                Text(verse.displayRef)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(ShepherdTheme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .widgetAccentable()

            fittedText([.subheadline, .footnote, .caption, .caption2])

            Spacer(minLength: 0)

            attribution
        }
    }

    private var medium: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: "sun.max.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ShepherdTheme.streak)
                Text("VERSE OF THE DAY")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(ShepherdTheme.accent)
            }
            .widgetAccentable()

            fittedText([.body, .callout, .subheadline, .footnote])

            Spacer(minLength: 0)

            HStack(alignment: .firstTextBaseline) {
                Text(verse.displayRef)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(ShepherdTheme.accent)
                    .widgetAccentable()
                Spacer()
                attribution
            }
        }
    }

    private var attribution: some View {
        Text("World English Bible")
            .font(.caption2)
            .foregroundStyle(ShepherdTheme.textTertiary)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }

    /// The largest style at which the whole verse fits; the smallest one shrinks if it must.
    private func fittedText(_ styles: [Font.TextStyle]) -> some View {
        ViewThatFits(in: .vertical) {
            ForEach(Array(styles.dropLast().enumerated()), id: \.offset) { _, style in
                verseText(style).fixedSize(horizontal: false, vertical: true)
            }
            verseText(styles.last ?? .caption2).minimumScaleFactor(0.7)
        }
    }

    private func verseText(_ style: Font.TextStyle) -> some View {
        Text(verse.text)
            .font(.system(style, design: .serif))
            .foregroundStyle(ShepherdTheme.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// What the streak widgets say about today, derived from the published data at `date`.
public enum StreakWidgetStatus: Equatable {
    case doneToday
    case lessonWaiting(day: Int, title: String?)
    case pathComplete

    public init(data: WidgetStreakData, date: Date, calendar: Calendar = .current) {
        if data.isCompleted(on: date, calendar: calendar) {
            self = .doneToday
        } else if let day = data.nextLessonDayIndex {
            self = .lessonWaiting(day: day, title: data.nextLessonTitle)
        } else {
            self = .pathComplete
        }
    }

    var spoken: String {
        switch self {
        case .doneToday: return "Today's lesson is done."
        case .lessonWaiting(let day, let title):
            return "Day \(day)\(title.map { ", \($0)" } ?? "") is ready."
        case .pathComplete: return "Path complete."
        }
    }
}

private func streakLabel(_ count: Int) -> String {
    count == 1 ? "1-day streak" : "\(count)-day streak"
}

/// Small Home Screen widget: streak and today's lesson status.
public struct StreakWidgetView: View {
    public let data: WidgetStreakData
    public let date: Date

    public init(data: WidgetStreakData, date: Date) {
        self.data = data
        self.date = date
    }

    private var status: StreakWidgetStatus { StreakWidgetStatus(data: data, date: date) }

    public var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.headline)
                    .foregroundStyle(ShepherdTheme.streak)
                    .widgetAccentable()
                Text("\(data.streakCount)")
                    .font(.system(.largeTitle, design: .rounded, weight: .heavy))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
            }
            Text("day streak")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ShepherdTheme.textSecondary)

            Spacer(minLength: 0)

            statusView
        }
        .widgetURL(DeepLink.lesson)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streakLabel(data.streakCount)). \(status.spoken)")
    }

    @ViewBuilder
    private var statusView: some View {
        switch status {
        case .doneToday:
            Label("Today done", systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.bold))
                .foregroundStyle(ShepherdTheme.accent)
                .widgetAccentable()
            Text("See you tomorrow")
                .font(.caption2)
                .foregroundStyle(ShepherdTheme.textSecondary)
        case .lessonWaiting(let day, let title):
            Text("Day \(day)")
                .font(.caption.weight(.bold))
                .foregroundStyle(ShepherdTheme.accent)
                .widgetAccentable()
            if let title, !title.isEmpty {
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(ShepherdTheme.textSecondary)
                    .lineLimit(2)
            }
        case .pathComplete:
            Text("Path complete")
                .font(.caption.weight(.bold))
                .foregroundStyle(ShepherdTheme.accent)
                .widgetAccentable()
            Text(data.activePathTitle)
                .font(.caption2)
                .foregroundStyle(ShepherdTheme.textSecondary)
                .lineLimit(2)
        }
    }
}

/// Lock Screen accessories. The circular gauge is today's step: full once today's lesson is done.
public struct LockScreenStreakView: View {
    public let data: WidgetStreakData
    public let date: Date
    public let family: WidgetFamily

    public init(data: WidgetStreakData, date: Date, family: WidgetFamily) {
        self.data = data
        self.date = date
        self.family = family
    }

    private var status: StreakWidgetStatus { StreakWidgetStatus(data: data, date: date) }

    public var body: some View {
        Group {
            switch family {
            case .accessoryCircular: circular
            case .accessoryInline: inline
            default: rectangular
            }
        }
        .widgetURL(DeepLink.lesson)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(streakLabel(data.streakCount)). \(status.spoken)")
    }

    private var circular: some View {
        Gauge(value: status == .doneToday ? 1 : 0) {
            Image(systemName: "flame.fill")
        } currentValueLabel: {
            Text("\(data.streakCount)")
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
        .gaugeStyle(.accessoryCircularCapacity)
        .widgetAccentable()
    }

    private var rectangular: some View {
        VStack(alignment: .leading, spacing: 1) {
            Label(streakLabel(data.streakCount), systemImage: "flame.fill")
                .font(.headline)
                .widgetAccentable()
            Text(statusLine)
                .font(.caption)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var inline: some View {
        Label("\(streakLabel(data.streakCount)) · \(shortStatus)", systemImage: "flame.fill")
    }

    private var statusLine: String {
        switch status {
        case .doneToday: return "Today done ✓"
        case .lessonWaiting(let day, let title): return "Day \(day)\(title.map { " · \($0)" } ?? "")"
        case .pathComplete: return "Path complete"
        }
    }

    private var shortStatus: String {
        switch status {
        case .doneToday: return "done today"
        case .lessonWaiting(let day, _): return "Day \(day)"
        case .pathComplete: return "path complete"
        }
    }
}
