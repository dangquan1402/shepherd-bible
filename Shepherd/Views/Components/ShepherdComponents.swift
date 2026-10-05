import SwiftUI
import StoreKit

// MARK: - Navigation Glass Toolbar Items

public struct GlassToolbarButton: View {
    public let systemImage: String
    public var action: () -> Void

    public init(systemImage: String, action: @escaping () -> Void) {
        self.systemImage = systemImage
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.glass)
        .accessibilityLabel(systemImage)
    }
}

public struct StreakChip: View {
    public let streak: Int
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public init(streak: Int) {
        self.streak = streak
    }

    public var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Color.shepherdAccentFill)
                .font(.system(size: 16))
                .symbolEffect(.bounce, value: streak)
            Text("\(streak)")
                .font(.system(size: 16, weight: .bold))
                .contentTransition(.numericText())
                .foregroundStyle(Color.shepherdTextPrimary)
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .shepherdGlassCard(cornerRadius: ShepherdTheme.radiusPill)
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
                    .font(.system(size: 17, weight: .bold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
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
                    .font(.system(size: 17, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 56)
        }
        .buttonStyle(.glass)
    }
}

// MARK: - 3D Path Node Component

public enum PathNodeState {
    case current
    case done
    case locked
    case milestoneLocked
}

public struct PathNodeView: View {
    public let dayNumber: Int
    public let state: PathNodeState
    public var action: () -> Void

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

                // Icon / Content
                switch state {
                case .current:
                    VStack(spacing: 2) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(.white)
                        Text("Day \(dayNumber)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(.white)
                    }
                case .done:
                    Image(systemName: "checkmark")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(ShepherdTheme.accentFill)
                case .locked:
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                case .milestoneLocked:
                    Image(systemName: "flag.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundStyle(ShepherdTheme.textTertiary)
                }
            }
            .frame(width: 84, height: 92)
            .opacity(state == .locked || state == .milestoneLocked ? 0.65 : 1.0)
        }
        .buttonStyle(.plain)
    }

    private var faceColor: Color {
        switch state {
        case .current: return ShepherdTheme.accentFill
        case .done: return ShepherdTheme.accentSubtle
        case .locked, .milestoneLocked: return ShepherdTheme.nodeLocked
        }
    }

    private var baseColor: Color {
        switch state {
        case .current: return ShepherdTheme.accentFillDeep
        case .done: return ShepherdTheme.accentSubtleDeep
        case .locked, .milestoneLocked: return ShepherdTheme.nodeLockedDeep
        }
    }

    private var ringColor: Color {
        switch state {
        case .current: return ShepherdTheme.nodeCurrentRing
        case .done: return ShepherdTheme.accentFill.opacity(0.3)
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
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(letterTextColor)
                    .frame(width: 32, height: 32)
                    .background(letterBgColor)
                    .clipShape(Circle())

                // Prompt text
                Text(text)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(ShepherdTheme.textPrimary)
                    .multilineTextAlignment(.leading)

                Spacer()

                // State Icon
                switch state {
                case .selected:
                    Circle()
                        .strokeBorder(ShepherdTheme.accent, lineWidth: 2)
                        .frame(width: 24, height: 24)
                case .correct, .revealed:
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ShepherdTheme.success)
                case .wrong:
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(ShepherdTheme.error)
                case .neutral:
                    EmptyView()
                }
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
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
        case .selected: return ShepherdTheme.accentSubtle
        case .correct, .revealed: return ShepherdTheme.successSubtle
        case .wrong: return ShepherdTheme.errorSubtle
        }
    }

    private var borderColor: Color {
        switch state {
        case .neutral: return ShepherdTheme.surfaceBorder
        case .selected: return ShepherdTheme.accent
        case .correct, .revealed: return ShepherdTheme.success
        case .wrong: return ShepherdTheme.error
        }
    }

    private var letterBgColor: Color {
        switch state {
        case .selected: return ShepherdTheme.accent
        case .correct, .revealed: return ShepherdTheme.success
        case .wrong: return ShepherdTheme.error
        case .neutral: return ShepherdTheme.surfaceSunken
        }
    }

    private var letterTextColor: Color {
        switch state {
        case .selected, .correct, .revealed, .wrong: return .white
        case .neutral: return ShepherdTheme.textSecondary
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
            Text("\(reference.uppercased()) · \(translation)")
                .font(ShepherdTheme.scriptureEyebrow())
                .foregroundStyle(ShepherdTheme.accent)

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

    public init(icon: String, text: String, color: Color = ShepherdTheme.accentFill) {
        self.icon = icon
        self.text = text
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(color)
            Text(text)
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(ShepherdTheme.textPrimary)
        }
        .padding(.horizontal, 16)
        .frame(height: 48)
        .background(ShepherdTheme.cardSurface)
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
        )
    }
}

// MARK: - Paywall Plan Card

public struct PlanCard: View {
    public let title: String
    public let subtitle: String
    public let price: String
    public var badge: String? = nil
    public let isSelected: Bool
    public var action: () -> Void

    public init(
        title: String,
        subtitle: String,
        price: String,
        badge: String? = nil,
        isSelected: Bool,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.price = price
        self.badge = badge
        self.isSelected = isSelected
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                // Radio icon
                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(ShepherdTheme.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title)
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(ShepherdTheme.textPrimary)

                        if let badge {
                            Text(badge.uppercased())
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(ShepherdTheme.accentSubtle)
                                .foregroundStyle(ShepherdTheme.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(subtitle)
                        .font(.system(size: 13))
                        .foregroundStyle(ShepherdTheme.textSecondary)
                }

                Spacer()

                Text(price)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(ShepherdTheme.textPrimary)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(isSelected ? ShepherdTheme.accentSubtle.opacity(0.3) : ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD))
            .overlay(
                RoundedRectangle(cornerRadius: ShepherdTheme.radiusMD)
                    .stroke(isSelected ? ShepherdTheme.accent : ShepherdTheme.surfaceBorder, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}
