import SwiftUI
import WidgetKit

public struct LockScreenStreakWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    var entry: StreakEntry

    var data: WidgetStreakData { entry.data }

    public init(entry: StreakEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .accessoryCircular:
            circularView
        case .accessoryRectangular:
            rectangularView
        case .accessoryInline:
            inlineView
        default:
            rectangularView
        }
    }

    private var circularView: some View {
        ZStack {
            Gauge(value: data.isCompletedToday ? 1.0 : 0.5) {
                Image(systemName: "flame.fill")
            } currentValueLabel: {
                Text("\(data.streakCount)")
                    .font(.headline.weight(.bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
        }
        .widgetURL(URL(string: "pasture://lesson"))
        .accessibilityLabel("Streak: \(data.streakCount) days. \(data.isCompletedToday ? "Lesson completed today." : "Lesson waiting.")")
    }

    private var rectangularView: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: "flame.fill")
                    .font(.caption.weight(.bold))
                Text("Streak: \(data.streakCount) \(data.streakCount == 1 ? "day" : "days")")
                    .font(.caption.weight(.bold))
            }

            if data.isCompletedToday {
                Text("✓ Today done")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                let dayNum = data.nextLessonDayIndex ?? 1
                Text("Day \(dayNum) ready")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .widgetURL(URL(string: "pasture://lesson"))
        .accessibilityLabel("Streak: \(data.streakCount) days. \(data.isCompletedToday ? "Today done" : "Today ready")")
    }

    private var inlineView: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
            Text("\(data.streakCount)d · \(data.isCompletedToday ? "Done" : "Day \(data.nextLessonDayIndex ?? 1)")")
        }
        .widgetURL(URL(string: "pasture://lesson"))
    }
}

public struct LockScreenStreakWidget: Widget {
    public let kind: String = "PastureLockScreenStreakWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            LockScreenStreakWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Streak (Lock Screen)")
        .description("Glance at your streak and daily step right on your Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}
