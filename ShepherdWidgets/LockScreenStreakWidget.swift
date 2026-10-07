import SwiftUI
import WidgetKit

public struct LockScreenStreakWidget: Widget {
    public let kind: String = "PastureLockScreenStreakWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StreakTimelineProvider()) { entry in
            LockScreenStreakEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Streak")
        .description("Your streak and today's lesson on the Lock Screen.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct LockScreenStreakEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: StreakEntry

    var body: some View {
        LockScreenStreakView(data: entry.data, date: entry.date, family: family)
    }
}
