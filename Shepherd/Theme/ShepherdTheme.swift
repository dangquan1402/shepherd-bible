import SwiftUI

// MARK: - Shepherd Design Tokens (iOS 26 Liquid Glass)

public enum ShepherdTheme {
    // MARK: - Colors: Canvas & Surfaces
    public static let canvasBg = Color("CanvasBg")
    public static let cardSurface = Color("CardSurface")
    public static let surfaceSunken = Color("SurfaceSunken")
    public static let surfaceBorder = Color("SurfaceBorder")
    public static let textPrimary = Color("TextPrimary")
    public static let textSecondary = Color("TextSecondary")
    public static let textTertiary = Color("TextTertiary")
    public static let onAccent = Color("OnAccent")
    public static let canvasClear = Color("CanvasClear")
    public static let canvasVeil = Color("CanvasVeil")

    // MARK: - Colors: Accent & Gold
    public static let accent = Color("AccentColor")
    public static let accentFill = Color("AccentFill")
    public static let accentSubtle = Color("AccentSubtle")
    public static let accentFillDeep = Color("AccentFillDeep")
    public static let accentSubtleDeep = Color("AccentSubtleDeep")
    public static let gold = Color("Gold")
    public static let goldFill = Color("GoldFill")
    public static let goldSubtle = Color("GoldSubtle")
    public static let nodeCurrentRing = Color("NodeCurrentRing")
    public static let nodeGlow = Color("NodeGlow")
    public static let nodeLocked = Color("NodeLocked")
    public static let nodeLockedDeep = Color("NodeLockedDeep")

    // MARK: - Colors: Quiz Correctness (Quiz only)
    public static let success = Color("Success")
    public static let successSubtle = Color("SuccessSubtle")
    public static let successFill = Color("SuccessFill")
    public static let successDeep = Color("SuccessDeep")
    public static let error = Color("Error")
    public static let errorSubtle = Color("ErrorSubtle")

    // MARK: - Colors: Scripture Highlights
    public static let highlightYellow = Color("HighlightYellow")
    public static let highlightBlue = Color("HighlightBlue")
    public static let highlightPurple = Color("HighlightPurple")
    public static let highlightRose = Color("HighlightRose")
    public static let highlightAmber = Color("HighlightAmber")

    // MARK: - Colors: Liquid Glass
    public static let glassFill = Color("GlassFill")
    public static let glassStroke = Color("GlassStroke")
    public static let glassSpecular = Color("GlassSpecular")
    public static let shadowGlass = Color("ShadowGlass")
    public static let shadowGlassHeavy = Color("ShadowGlassHeavy")
    public static let scrim = Color("Scrim")
    public static let scrimSoft = Color("ScrimSoft")
    public static let glassSpecTop = Color("GlassSpecTop")
    public static let glassSpecMid = Color("GlassSpecMid")
    public static let glassSpecBottom = Color("GlassSpecBottom")
    public static let glassInnerHi = Color("GlassInnerHi")
    public static let tabSelection = Color("TabSelection")

    // MARK: - Colors: Meadow Illustration
    public static let meadowSky = Color("MeadowSky")
    public static let meadowSkyBottom = Color("MeadowSkyBottom")
    public static let meadowSkyClear = Color("MeadowSkyClear")
    public static let meadowSkyVeil = Color("MeadowSkyVeil")
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
    static var shepherdAccent: Color { ShepherdTheme.accent }
    static var shepherdAccentFill: Color { ShepherdTheme.accentFill }
    static var shepherdCanvasBg: Color { ShepherdTheme.canvasBg }
    static var shepherdCardSurface: Color { ShepherdTheme.cardSurface }
    static var shepherdTextPrimary: Color { ShepherdTheme.textPrimary }
    static var shepherdTextSecondary: Color { ShepherdTheme.textSecondary }
    static var shepherdTextTertiary: Color { ShepherdTheme.textTertiary }
    static var shepherdSuccess: Color { ShepherdTheme.success }
    static var shepherdError: Color { ShepherdTheme.error }
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
