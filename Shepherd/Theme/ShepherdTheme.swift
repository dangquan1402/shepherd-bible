import SwiftUI

// MARK: - Shepherd Design Tokens (iOS 26 Liquid Glass)

public enum ShepherdTheme {
    // MARK: - Colors: Canvas & Surfaces
    public static let canvasBg = Color("CanvasBg")
    public static let cardSurface = Color("CardSurface")
    public static let surfaceSunken = Color("SurfaceSunken")
    public static let surfaceBorder = Color("SurfaceBorder")
    public static let borderStrong = Color("BorderStrong")
    public static let textPrimary = Color("TextPrimary")
    public static let textSecondary = Color("TextSecondary")
    public static let textTertiary = Color("TextTertiary")

    // MARK: - Colors: Brand
    public static let brand = Color("AccentColor")
    public static let brandFill = Color("BrandFill")
    public static let brandSubtle = Color("BrandSubtle")
    public static let brandFillDeep = Color("BrandFillDeep")
    public static let brandSubtleDeep = Color("BrandSubtleDeep")
    public static let onBrand = Color("OnBrand")

    // MARK: - Colors: Joy & Reward
    public static let joy = Color("Joy")
    public static let joyFill = Color("JoyFill")
    public static let joySubtle = Color("JoySubtle")
    public static let streak = Color("Streak")

    // MARK: - Colors: Status & Roles
    public static let destructive = Color("Destructive")
    public static let premiumSurface = Color("PremiumSurface")
    public static let onPremium = Color("OnPremium")
    public static let premiumGlyph = Color("PremiumGlyph")

    // MARK: - Colors: Today Path Node
    public static let nodeCurrentRing = Color("NodeCurrentRing")
    public static let nodeGlow = Color("NodeGlow")
    public static let nodeLocked = Color("NodeLocked")
    public static let nodeLockedDeep = Color("NodeLockedDeep")

    // MARK: - Colors: Quiz Correctness (Quiz only)
    public static let correct = Color("Correct")
    public static let correctSubtle = Color("CorrectSubtle")
    public static let wrong = Color("Wrong")
    public static let wrongSubtle = Color("WrongSubtle")

    // Backward-compatibility aliases during transition
    public static let accent = brand
    public static let accentFill = brandFill
    public static let accentSubtle = brandSubtle
    public static let accentFillDeep = brandFillDeep
    public static let accentSubtleDeep = brandSubtleDeep
    public static let onAccent = onBrand
    public static let gold = joy
    public static let goldFill = joyFill
    public static let goldSubtle = joySubtle
    public static let success = correct
    public static let successSubtle = correctSubtle
    public static let error = wrong
    public static let errorSubtle = wrongSubtle

    // MARK: - Colors: Scripture Highlights
    public static let highlightYellow = Color("HighlightYellow")
    public static let highlightBlue = Color("HighlightBlue")
    public static let highlightPurple = Color("HighlightPurple")
    public static let highlightRose = Color("HighlightRose")
    public static let highlightAmber = Color("HighlightAmber")

    // MARK: - Colors: Liquid Glass
    public static let glassStroke = Color("GlassStroke")
    public static let shadowGlass = Color("ShadowGlass")
    public static let scrim = Color("Scrim")
    public static let scrimSoft = Color("ScrimSoft")
    public static let tabSelection = Color("TabSelection")

    // MARK: - Colors: Meadow Illustration
    public static let meadowSky = Color("MeadowSky")
    public static let meadowSkyBottom = Color("MeadowSkyBottom")
    public static let meadowHillNear = Color("MeadowHillNear")
    public static let meadowHillMid = Color("MeadowHillMid")
    public static let meadowHillDistant = Color("MeadowHillDistant")
    public static let meadowPath = Color("MeadowPath")
    public static let meadowPathBorder = Color("MeadowPathBorder")

    // MARK: - Colors: Lamb Mascot
    public static let mascotFleece = Color("MascotFleece")
    public static let mascotFleeceShade = Color("MascotFleeceShade")
    public static let mascotFace = Color("MascotFace")
    public static let mascotFeatures = Color("MascotFeatures")
    public static let mascotFarLegs = Color("MascotFarLegs")
    public static let mascotBlush = Color("MascotBlush")
    public static let mascotOutline = Color("MascotOutline")
    public static let mascotShadow = Color("MascotShadow")
    public static let mascotTongue = Color("MascotTongue")
    public static let mascotBell = Color("MascotBell")
    public static let mascotHoof = Color("MascotHoof")
    public static let mascotCatchlight = Color("MascotCatchlight")
    public static let mascotLegs = Color("MascotLegs")
    public static let mascotEyeWhite = Color("MascotEyeWhite")
    public static let mascotMouth = Color("MascotMouth")
    public static let mascotFlower = Color("MascotFlower")
    public static let mascotZz = Color("MascotZz")

    // MARK: - Spacing Tokens
    public static let space1: CGFloat = 4
    public static let space2: CGFloat = 8
    public static let space3: CGFloat = 12
    public static let space4: CGFloat = 16
    public static let space5: CGFloat = 20
    public static let space6: CGFloat = 24
    public static let space8: CGFloat = 32
    public static let space10: CGFloat = 40

    // MARK: - Radius Tokens
    public static let radiusXS: CGFloat = 4
    public static let radiusSM: CGFloat = 8
    public static let radiusMD: CGFloat = 14
    public static let radiusLG: CGFloat = 20
    public static let radiusXL: CGFloat = 28
    public static let radiusPill: CGFloat = 999

    // MARK: - Motion Springs
    public static let morphSpring = Animation.spring(duration: 0.35, bounce: 0.15)
    public static let xpFillSpring = Animation.spring(duration: 0.6, bounce: 0.1)
    public static let stageUpSpring = Animation.spring(duration: 0.5, bounce: 0.25)
    public static let tiltSpring = Animation.spring(duration: 0.4, bounce: 0.2)

    // MARK: - Typography (Dynamic Type SF Pro for UI, Serif for Scripture & Titles)
    public static func largeTitleSerif() -> Font {
        .system(.largeTitle, design: .serif, weight: .bold)
    }

    public static func title1Serif() -> Font {
        .system(.title, design: .serif, weight: .bold)
    }

    public static func title2Serif() -> Font {
        .system(.title2, design: .serif, weight: .bold)
    }

    public static func title3Serif() -> Font {
        .system(.title3, design: .serif, weight: .bold)
    }

    public static func scriptureBody() -> Font {
        .system(.title3, design: .serif, weight: .regular)
    }

    public static func scriptureEyebrow() -> Font {
        .footnote.weight(.bold)
    }
}

// MARK: - Color Convenience Extensions
public extension Color {
    static var shepherdBrand: Color { ShepherdTheme.brand }
    static var shepherdBrandFill: Color { ShepherdTheme.brandFill }
    static var shepherdAccent: Color { ShepherdTheme.brand }
    static var shepherdAccentFill: Color { ShepherdTheme.brandFill }
    static var shepherdCanvasBg: Color { ShepherdTheme.canvasBg }
    static var shepherdCardSurface: Color { ShepherdTheme.cardSurface }
    static var shepherdTextPrimary: Color { ShepherdTheme.textPrimary }
    static var shepherdTextSecondary: Color { ShepherdTheme.textSecondary }
    static var shepherdTextTertiary: Color { ShepherdTheme.textTertiary }
    static var shepherdCorrect: Color { ShepherdTheme.correct }
    static var shepherdWrong: Color { ShepherdTheme.wrong }
    static var shepherdSuccess: Color { ShepherdTheme.correct }
    static var shepherdError: Color { ShepherdTheme.wrong }
    static var shepherdJoy: Color { ShepherdTheme.joy }
    static var shepherdJoyFill: Color { ShepherdTheme.joyFill }
    static var shepherdDestructive: Color { ShepherdTheme.destructive }
    static var shepherdStreak: Color { ShepherdTheme.streak }
    static var shepherdGlassStroke: Color { ShepherdTheme.glassStroke }
    static var shepherdHighlightYellow: Color { ShepherdTheme.highlightYellow }
    static var shepherdHighlightBlue: Color { ShepherdTheme.highlightBlue }
    static var shepherdHighlightPurple: Color { ShepherdTheme.highlightPurple }
    static var shepherdHighlightRose: Color { ShepherdTheme.highlightRose }
    static var shepherdHighlightAmber: Color { ShepherdTheme.highlightAmber }
}

// MARK: - Liquid Glass View Modifier with Accessibility Fallback
public struct ShepherdGlassCardModifier: ViewModifier {
    public var cornerRadius: CGFloat = 28
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    public func body(content: Content) -> some View {
        if reduceTransparency {
            content
                .background(ShepherdTheme.cardSurface)
                .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(ShepherdTheme.glassStroke, lineWidth: 1)
                )
                .shadow(color: ShepherdTheme.shadowGlass, radius: 12, x: 0, y: 6)
        } else {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
                .shadow(color: ShepherdTheme.shadowGlass, radius: 24, x: 0, y: 8)
        }
    }
}

public extension View {
    func shepherdGlassCard(cornerRadius: CGFloat = 28) -> some View {
        modifier(ShepherdGlassCardModifier(cornerRadius: cornerRadius))
    }
}

public extension View {
    /// The flat row card used by the Lamb tab and the Journal: card surface with a hairline border.
    func shepherdSurfaceCard(cornerRadius: CGFloat = ShepherdTheme.radiusMD) -> some View {
        background(ShepherdTheme.cardSurface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ShepherdTheme.surfaceBorder, lineWidth: 1)
            )
    }
}
