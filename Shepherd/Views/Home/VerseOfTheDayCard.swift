import SwiftUI

public struct VerseOfTheDayCard: View {
    public let verse: DailyVerse
    public var onOpen: () -> Void

    public init(verse: DailyVerse, onOpen: @escaping () -> Void) {
        self.verse = verse
        self.onOpen = onOpen
    }

    public var body: some View {
        Button(action: onOpen) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack(spacing: 8) {
                    Image(systemName: "sun.max.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(ShepherdTheme.streak)

                    Text("VERSE OF THE DAY")
                        .font(ShepherdTheme.scriptureEyebrow())
                        .foregroundStyle(ShepherdTheme.brand)
                        .tracking(0.6)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }

                // Scripture body
                Text(verse.text)
                    .font(ShepherdTheme.scriptureBody())
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .lineSpacing(5)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                // Footer: Reference + Attribution
                HStack(alignment: .firstTextBaseline) {
                    Text(verse.displayRef)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(ShepherdTheme.brand)

                    Spacer()

                    Text("World English Bible")
                        .font(.caption)
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
                .padding(.top, 2)
            }
            .padding(18)
            .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusLG)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Verse of the day. \(verse.spokenLabel)")
        .accessibilityHint("Opens the verse in the Bible.")
        .accessibilityAddTraits(.isButton)
    }
}
