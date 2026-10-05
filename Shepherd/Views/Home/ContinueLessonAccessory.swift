import SwiftUI

public struct ContinueLessonAccessory: View {
    public let lesson: Lesson
    public var onSelect: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    public init(lesson: Lesson, onSelect: @escaping () -> Void) {
        self.lesson = lesson
        self.onSelect = onSelect
    }

    public var body: some View {
        Button(action: onSelect) {
            if placement == .inline {
                // Morph B: Inline placement beside minimized tab bar
                HStack(spacing: 8) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(ShepherdTheme.accentFill)

                    Text("Day \(lesson.dayIndex) · \(lesson.title)")
                        .font(.callout.weight(.semibold))
                        .foregroundStyle(ShepherdTheme.textPrimary)
                }
                .padding(.horizontal, 14)
                .frame(minHeight: 52)
            } else {
                // Morph B: Expanded placement above full tab bar
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(ShepherdTheme.accentFill)
                            .frame(width: 40, height: 40)
                        Image(systemName: "play.fill")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("TODAY'S LESSON")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(ShepherdTheme.accent)

                        Text("Day \(lesson.dayIndex) · \(lesson.title)")
                            .font(.callout.weight(.semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .frame(minHeight: 56)
            }
        }
        .buttonStyle(.plain)
    }
}
