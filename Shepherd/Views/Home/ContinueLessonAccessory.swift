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
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textPrimary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
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
                        Text("CONTINUE PATH · DAY \(lesson.dayIndex)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(ShepherdTheme.accent)

                        Text(lesson.title)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textPrimary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .padding(.horizontal, 16)
                .frame(height: 56)
            }
        }
        .buttonStyle(.plain)
    }
}
