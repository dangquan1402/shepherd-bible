import SwiftUI
import StoreKit

// MARK: - Meadow Hill Vignette (Mascot pedestal per design spec)

public struct HillVignetteShape: Shape {
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let sx = rect.width / 320.0
        let sy = rect.height / 70.0
        path.move(to: CGPoint(x: 0, y: 70 * sy))
        path.addCurve(
            to: CGPoint(x: 160 * sx, y: 6 * sy),
            control1: CGPoint(x: 40 * sx, y: 20 * sy),
            control2: CGPoint(x: 110 * sx, y: 6 * sy)
        )
        path.addCurve(
            to: CGPoint(x: 320 * sx, y: 70 * sy),
            control1: CGPoint(x: 210 * sx, y: 6 * sy),
            control2: CGPoint(x: 280 * sx, y: 20 * sy)
        )
        path.closeSubpath()
        return path
    }
}

public struct HillVignetteView: View {
    public var width: CGFloat = 320
    public var height: CGFloat = 70

    public init(width: CGFloat = 320, height: CGFloat = 70) {
        self.width = width
        self.height = height
    }

    public var body: some View {
        HillVignetteShape()
            .fill(
                LinearGradient(
                    colors: [ShepherdTheme.meadowHillNear, ShepherdTheme.meadowHillMid],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .frame(width: width, height: height)
    }
}

public struct StreakChip: View {
    public let streak: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(streak: Int) {
        self.streak = streak
    }

    public var body: some View {
        Button {} label: {
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .foregroundStyle(ShepherdTheme.streak)
                    .symbolEffect(.bounce, value: reduceMotion ? 0 : streak)
                Text("\(streak)")
                    .font(.body.weight(.bold))
                    .contentTransition(.numericText())
                    .foregroundStyle(Color.shepherdTextPrimary)
            }
        }
        .buttonStyle(.glass)
        .sensoryFeedback(.impact(weight: .light), trigger: streak)
    }
}

// MARK: - Primary & Secondary Action Buttons

public struct ProminentGlassButton: View {
    public let title: String
    public var icon: String? = nil
    public var isEnabled: Bool = true
    public var action: () -> Void

    public init(_ title: String, icon: String? = nil, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isEnabled = isEnabled
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.body.weight(.bold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
        }
        .buttonStyle(.glassProminent)
        .tint(ShepherdTheme.accentFill)
        .disabled(!isEnabled)
    }
}

public struct SecondaryGlassButton: View {
    public let title: String
    public var icon: String? = nil
    public var action: () -> Void

    public init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
        }
        .buttonStyle(.glass)
    }
}

// MARK: - 3D Path Node Component

public enum PathNodeState: Equatable {
    case current
    case done
    case locked
    case milestoneLocked
    /// The next lesson, but behind Premium: tappable, opens the paywall.
    case premiumLocked
}

public struct PathNodeView: View {
    public let dayNumber: Int
    public let state: PathNodeState
    public var action: () -> Void

    @State private var unlockRingScale: CGFloat = 36
    @State private var unlockRingOpacity: Double = 0.0
    @State private var showLockFadingOut: Bool = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(dayNumber: Int, state: PathNodeState, action: @escaping () -> Void) {
        self.dayNumber = dayNumber
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: {
            if state != .locked && state != .milestoneLocked {
                action()
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    // Soft glow for current node
                    if state == .current {
                        Circle()
                            .fill(ShepherdTheme.nodeGlow)
                            .frame(width: 96, height: 96)
                            .blur(radius: 8)
                    }

                    // Node Base / 3D Lip
                    Circle()
                        .fill(baseColor)
                        .frame(width: 84, height: 84)
                        .offset(y: 6)

                    // Node Face
                    Circle()
                        .fill(faceColor)
                        .frame(width: 84, height: 84)
                        .overlay(
                            Circle()
                                .stroke(ringColor, lineWidth: state == .current ? 6 : 1.5)
                        )

                    // Row 13: Node unlock ring
                    Circle()
                        .stroke(ShepherdTheme.accentFill, lineWidth: 3)
                        .frame(width: unlockRingScale, height: unlockRingScale)
                        .opacity(unlockRingOpacity)

                    // Base Icon
                    switch state {
                    case .current:
                        Image(systemName: "book.fill")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundStyle(ShepherdTheme.onAccent)
                    case .done:
                        Image(systemName: "checkmark")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundStyle(ShepherdTheme.accent)
                    case .locked:
                        EmptyView()
                    case .milestoneLocked:
                        Image(systemName: "flag.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textTertiary)
                    case .premiumLocked:
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.accent)
                    }

                    // Lock Icon that animates disappearance on unlock
                    if state == .locked || showLockFadingOut {
                        Image(systemName: "lock.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundStyle(ShepherdTheme.textTertiary)
                            .symbolEffect(.disappear, isActive: state != .locked)
                    }
                }
                .frame(width: 84, height: 90)

                Text("Day \(dayNumber)")
                    .font(.caption.bold())
                    .foregroundStyle(state == .current ? ShepherdTheme.textPrimary : ShepherdTheme.textSecondary)
            }
            .frame(width: 96)
            .opacity(state == .locked || state == .milestoneLocked ? 0.75 : 1.0)
        }
        .buttonStyle(.plain)
        .disabled(state == .locked || state == .milestoneLocked)
        .accessibilityLabel("Day \(dayNumber)\(accessibilitySuffix)")
        .onChange(of: state) { oldState, newState in
            if oldState == .locked && newState == .current {
                showLockFadingOut = true
                Task {
                    try? await Task.sleep(nanoseconds: 600_000_000)
                    showLockFadingOut = false
                }
                if !reduceMotion {
                    unlockRingScale = 36
                    unlockRingOpacity = 0.8
                    withAnimation(.easeOut(duration: 0.6)) {
                        unlockRingScale = 52
                        unlockRingOpacity = 0.0
                    }
                }
            }
        }
    }

    private var accessibilitySuffix: String {
        switch state {
        case .locked, .milestoneLocked: return ", locked"
        case .done: return ", completed"
        case .current: return ", current"
        case .premiumLocked: return ", Premium"
        }
    }

    private var faceColor: Color {
        switch state {
        case .current: return ShepherdTheme.accentFill
        case .done: return ShepherdTheme.accentSubtle
        case .locked, .milestoneLocked, .premiumLocked: return ShepherdTheme.nodeLocked
        }
    }

    private var baseColor: Color {
        switch state {
        case .current: return ShepherdTheme.accentFillDeep
        case .done: return ShepherdTheme.accentSubtleDeep
        case .locked, .milestoneLocked, .premiumLocked: return ShepherdTheme.nodeLockedDeep
        }
    }

    private var ringColor: Color {
        switch state {
        case .current: return ShepherdTheme.nodeCurrentRing
        case .done: return ShepherdTheme.accentFill.opacity(0.3)
        case .premiumLocked: return ShepherdTheme.accentFill
        case .locked, .milestoneLocked: return ShepherdTheme.surfaceBorder
        }
    }
}

// MARK: - Quiz Choice Row Component

public enum ChoiceRowState {
    case neutral
    case selected
    case correct
    case wrong
    case revealed
}

public struct ChoiceRow: View {
    public let letter: String
    public let text: String
    public let state: ChoiceRowState
    public var action: () -> Void

    public init(letter: String, text: String, state: ChoiceRowState, action: @escaping () -> Void) {
        self.letter = letter
        self.text = text
        self.state = state
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Choice letter badge
                Text(letter)
                    .font(.callout.weight(.bold))
                    .foregroundStyle(letterTextColor)
                    .frame(width: 32, height: 32)
                    .background(letterBgColor)
                    .clipShape(Circle())

                // Prompt text
                Text(text)
                    .font(.body.weight(.medium))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                // State Icon
                switch state {
                case .selected:
                    Circle()
                        .strokeBorder(ShepherdTheme.textPrimary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                case .correct, .revealed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ShepherdTheme.correct)
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ShepherdTheme.wrong)
                case .neutral:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 60)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(borderColor, lineWidth: state == .neutral ? 1 : 2)
            )
        }
        .buttonStyle(.plain)
    }

    private var bgColor: Color {
        switch state {
        case .neutral: return ShepherdTheme.cardSurface
        case .selected: return ShepherdTheme.surfaceSunken
        case .correct, .revealed: return ShepherdTheme.correctSubtle
        case .wrong: return ShepherdTheme.wrongSubtle
        }
    }

    private var borderColor: Color {
        switch state {
        case .neutral: return ShepherdTheme.surfaceBorder
        case .selected: return ShepherdTheme.textPrimary
        case .correct, .revealed: return ShepherdTheme.correct
        case .wrong: return ShepherdTheme.wrong
        }
    }

    private var letterBgColor: Color { Color(state.letterBadgeColorNames.fill) }

    private var letterTextColor: Color { Color(state.letterBadgeColorNames.text) }
}

public extension ChoiceRowState {
    /// Colour-set names of the letter badge (text on fill). The fills are the text tokens
    /// brand/correct/wrong, which are light in dark mode, so the letter is the canvas colour,
    /// not white. `testChoiceLetterBadgeMeetsAA` and the `tokens.py` gate hold this to AA.
    var letterBadgeColorNames: (text: String, fill: String) {
        switch self {
        case .selected: return ("CanvasBg", "TextPrimary")
        case .correct, .revealed: return ("CanvasBg", "Correct")
        case .wrong: return ("CanvasBg", "Wrong")
        case .neutral: return ("TextSecondary", "SurfaceSunken")
        }
    }
}

// MARK: - Scripture Verse Card

public struct VerseCard: View {
    public let reference: String
    public let translation: String
    public let text: String

    public init(reference: String, translation: String = "WEB", text: String) {
        self.reference = reference
        self.translation = translation
        self.text = text
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("\(ContentStore.displayRef(reference)) · \(translation)")
                .font(ShepherdTheme.scriptureEyebrow())
                .foregroundStyle(ShepherdTheme.brand)

            Text(text)
                .font(ShepherdTheme.scriptureBody())
                .foregroundStyle(ShepherdTheme.textPrimary)
                .lineSpacing(6)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(ShepherdTheme.cardSurface)
        .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
        .overlay(
            RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - XP Progress Bar

public struct XPProgressBar: View {
    public let currentXP: Int
    public let maxXP: Int = 50

    public init(currentXP: Int) {
        self.currentXP = currentXP
    }

    public var body: some View {
        GeometryReader { geo in
            let progress = min(1.0, max(0.0, Double(currentXP % maxXP) / Double(maxXP)))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(ShepherdTheme.surfaceSunken)
                    .frame(height: 8)

                Capsule()
                    .fill(ShepherdTheme.accentFill)
                    .frame(width: geo.size.width * CGFloat(progress), height: 8)
            }
        }
        .frame(height: 8)
    }
}

// MARK: - Reward Stat Chip (for Lesson Complete)

public struct RewardStatChip: View {
    public let icon: String
    public let text: String
    public let color: Color
    public var fill: Color = ShepherdTheme.cardSurface

    public init(icon: String, text: String, color: Color = ShepherdTheme.accent, fill: Color = ShepherdTheme.cardSurface) {
        self.icon = icon
        self.text = text
        self.color = color
        self.fill = fill
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.body.weight(.bold))
                .foregroundStyle(ShepherdTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(minHeight: 48)
        .background(fill)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
        )
    }
}


// MARK: - Brand Lockup (design: Brand/Lockup, Brand/Lockup/Compact)

/// The mark (lamb face on the accent chip) beside the outlined `pasture` wordmark.
/// Both are vector assets; the wordmark is a template tinted with the accent token.
public struct BrandLockup: View {
    public enum Size {
        case regular   // onboarding welcome: 40 pt mark, 30 pt wordmark
        case compact   // paywall header: 30 pt mark, 21 pt wordmark

        var mark: CGFloat { self == .regular ? 40 : 30 }
        var word: CGFloat { self == .regular ? 30 : 21 }
    }

    public var size: Size

    public init(_ size: Size = .regular) {
        self.size = size
    }

    public var body: some View {
        HStack(spacing: size.mark * 0.28) {
            Image("BrandMark")
                .resizable()
                .frame(width: size.mark, height: size.mark)
            Image("Wordmark")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(height: size.word)
                .foregroundStyle(ShepherdTheme.accent)
                .offset(y: size.word * 0.08)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Pasture")
        .accessibilityIdentifier("brand_lockup")
    }
}
