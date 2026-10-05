import SwiftUI

// MARK: - Lamb Mascot System (iOS 26 Liquid Glass)

public enum LambStage: Int, CaseIterable, Identifiable, Codable {
    case newborn = 1
    case lamb = 2
    case youngSheep = 3
    case yearling = 4
    case grownSheep = 5

    public var id: Int { rawValue }

    public var name: String {
        switch self {
        case .newborn: return "Newborn"
        case .lamb: return "Lamb"
        case .youngSheep: return "Young sheep"
        case .yearling: return "Yearling"
        case .grownSheep: return "Grown sheep"
        }
    }

    public var xpThreshold: Int {
        switch self {
        case .newborn: return 0
        case .lamb: return 50
        case .youngSheep: return 100
        case .yearling: return 150
        case .grownSheep: return 200
        }
    }

    public var displayHeight: CGFloat {
        switch self {
        case .newborn: return 64
        case .lamb: return 80
        case .youngSheep: return 96
        case .yearling: return 108
        case .grownSheep: return 120
        }
    }

    public static func stage(forXP xp: Int) -> LambStage {
        let val = max(1, min(5, 1 + xp / 50))
        return LambStage(rawValue: val) ?? .newborn
    }
}

public enum LambExpression: String, CaseIterable, Identifiable {
    case idle = "Idle"
    case happy = "Happy"
    case encouraging = "Encouraging"
    case celebrating = "Celebrating"
    case sleepy = "Sleepy"
    case hello = "Hello"

    public var id: String { rawValue }
}

// MARK: - Fast SVG Polyline Parser (discretized M l m z paths)

public enum SVGPathParser {
    public static func parse(geometry: String) -> Path {
        var path = Path()
        let scanner = Scanner(string: geometry)
        scanner.caseSensitive = true
        var cur = CGPoint.zero
        var start = CGPoint.zero

        while !scanner.isAtEnd {
            if scanner.scanString("M") != nil {
                if let x = scanner.scanDouble(), let y = scanner.scanDouble() {
                    cur = CGPoint(x: x, y: y)
                    path.move(to: cur)
                    start = cur
                }
            } else if scanner.scanString("m") != nil {
                if let dx = scanner.scanDouble(), let dy = scanner.scanDouble() {
                    cur = CGPoint(x: cur.x + dx, y: cur.y + dy)
                    path.move(to: cur)
                    start = cur
                }
            } else if scanner.scanString("l") != nil {
                if let dx = scanner.scanDouble(), let dy = scanner.scanDouble() {
                    cur = CGPoint(x: cur.x + dx, y: cur.y + dy)
                    path.addLine(to: cur)
                }
            } else if scanner.scanString("z") != nil {
                path.closeSubpath()
                cur = start
            } else if let dx = scanner.scanDouble(), let dy = scanner.scanDouble() {
                cur = CGPoint(x: cur.x + dx, y: cur.y + dy)
                path.addLine(to: cur)
            } else {
                _ = scanner.scanCharacter()
            }
        }
        return path
    }
}

// MARK: - Geometry & Model Cache

public final class LambVariantStore: @unchecked Sendable {
    public static let shared = LambVariantStore()

    public struct ParsedLayer: Sendable {
        public let name: String
        public let fillKey: String
        public let path: Path
    }

    public struct ParsedVariant: Sendable {
        public let stage: Int
        public let expression: String
        public let width: CGFloat
        public let height: CGFloat
        public let viewBox: CGRect
        public let layers: [ParsedLayer]
    }

    public struct ParsedAvatar: Sendable {
        public let key: String
        public let width: CGFloat
        public let height: CGFloat
        public let layers: [ParsedLayer]
    }

    private var variantCache: [String: ParsedVariant] = [:]
    private var avatarCache: [String: ParsedAvatar] = [:]
    private var cachedGlyphPath: Path?
    private var cachedGlyphViewBox: CGRect = CGRect(x: 0.2, y: 14.5, width: 113.3, height: 87.5)
    private let lock = NSLock()

    private init() {
        loadData()
    }

    private func loadData() {
        guard let url = Bundle.main.url(forResource: "lamb_variants", withExtension: "json") else {
            return
        }
        guard let data = try? Data(contentsOf: url),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return
        }

        // Parse stages & expressions
        if let stages = json["stages"] as? [String: [String: Any]] {
            for (sKey, sVal) in stages {
                guard let sInt = Int(sKey),
                      let width = sVal["width"] as? Double,
                      let height = sVal["height"] as? Double,
                      let vbArr = sVal["viewBox"] as? [Double], vbArr.count >= 4,
                      let expressions = sVal["expressions"] as? [String: [[String: Any]]] else {
                    continue
                }
                let vb = CGRect(x: vbArr[0], y: vbArr[1], width: vbArr[2], height: vbArr[3])
                for (eKey, layersArr) in expressions {
                    var parsedLayers: [ParsedLayer] = []
                    for layerDict in layersArr {
                        guard let lName = layerDict["name"] as? String,
                              let lFill = layerDict["fill"] as? String,
                              let lGeom = layerDict["geometry"] as? String else { continue }
                        let path = SVGPathParser.parse(geometry: lGeom)
                        parsedLayers.append(ParsedLayer(name: lName, fillKey: lFill, path: path))
                    }
                    let key = "\(sInt)_\(eKey)"
                    variantCache[key] = ParsedVariant(
                        stage: sInt,
                        expression: eKey,
                        width: CGFloat(width),
                        height: CGFloat(height),
                        viewBox: vb,
                        layers: parsedLayers
                    )
                }
            }
        }

        // Parse avatars
        if let avatars = json["avatars"] as? [String: [String: Any]] {
            for (aKey, aVal) in avatars {
                guard let width = aVal["width"] as? Double,
                      let height = aVal["height"] as? Double,
                      let layersArr = aVal["layers"] as? [[String: Any]] else { continue }
                var parsedLayers: [ParsedLayer] = []
                for layerDict in layersArr {
                    guard let lName = layerDict["name"] as? String,
                          let lFill = layerDict["fill"] as? String,
                          let lGeom = layerDict["geometry"] as? String else { continue }
                    let path = SVGPathParser.parse(geometry: lGeom)
                    parsedLayers.append(ParsedLayer(name: lName, fillKey: lFill, path: path))
                }
                avatarCache[aKey] = ParsedAvatar(
                    key: aKey,
                    width: CGFloat(width),
                    height: CGFloat(height),
                    layers: parsedLayers
                )
            }
        }

        // Parse tab glyph
        if let glyph = json["glyph"] as? [String: Any],
           let geom = glyph["geometry"] as? String {
            cachedGlyphPath = SVGPathParser.parse(geometry: geom)
            if let vbArr = glyph["viewBox"] as? [Double], vbArr.count >= 4 {
                cachedGlyphViewBox = CGRect(x: vbArr[0], y: vbArr[1], width: vbArr[2], height: vbArr[3])
            }
        }
    }

    public func variant(stage: Int, expression: LambExpression) -> ParsedVariant? {
        lock.lock()
        defer { lock.unlock() }
        let key = "\(stage)_\(expression.rawValue)"
        return variantCache[key] ?? variantCache["\(stage)_Idle"]
    }

    public func avatar(key: String) -> ParsedAvatar? {
        lock.lock()
        defer { lock.unlock() }
        return avatarCache[key]
    }

    public var glyphPath: Path? {
        lock.lock()
        defer { lock.unlock() }
        return cachedGlyphPath
    }

    public var glyphViewBox: CGRect {
        cachedGlyphViewBox
    }

    public static func resolveColor(key: String) -> Color {
        switch key {
        case "mascotShadow": return ShepherdTheme.mascotShadow
        case "mascotOutline": return ShepherdTheme.mascotOutline
        case "mascotFarLegs": return ShepherdTheme.mascotFarLegs
        case "mascotFeatures": return ShepherdTheme.mascotFeatures
        case "mascotHoof": return ShepherdTheme.mascotHoof
        case "mascotFleece": return ShepherdTheme.mascotFleece
        case "mascotFleeceShade": return ShepherdTheme.mascotFleeceShade
        case "accentFill": return ShepherdTheme.accentFill
        case "mascotBell": return ShepherdTheme.mascotBell
        case "mascotFace": return ShepherdTheme.mascotFace
        case "mascotBlush": return ShepherdTheme.mascotBlush
        case "mascotCatchlight": return ShepherdTheme.mascotCatchlight
        case "mascotTongue": return ShepherdTheme.mascotTongue
        default: return ShepherdTheme.accent
        }
    }
}

// MARK: - Native Vector LambView

public struct LambView: View {
    public let stage: Int
    public let expression: LambExpression
    public var displayHeight: CGFloat?
    public var enableBlink: Bool = true

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var blinkTick: Int = 0

    public init(stage: Int = 1, expression: LambExpression = .idle, displayHeight: CGFloat? = nil, enableBlink: Bool = true) {
        self.stage = max(1, min(5, stage))
        self.expression = expression
        self.displayHeight = displayHeight
        self.enableBlink = enableBlink
    }

    public var body: some View {
        let store = LambVariantStore.shared
        if let variant = store.variant(stage: stage, expression: expression) {
            GeometryReader { geo in
                let targetH = displayHeight ?? geo.size.height
                let scale = targetH / variant.viewBox.height
                let targetW = variant.viewBox.width * scale
                let offsetX = (geo.size.width - targetW) / 2.0 - variant.viewBox.minX * scale
                let offsetY = (geo.size.height - targetH) / 2.0 - variant.viewBox.minY * scale

                let eyesPath = variant.layers.first(where: { $0.name == "Eyes" })?.path
                let eyeMidY = eyesPath?.boundingRect.midY ?? (variant.viewBox.minY + variant.viewBox.height * 0.4)
                let eyeCenterY = (eyeMidY * scale) + offsetY
                let eyeAnchor = UnitPoint(x: 0.5, y: max(0.1, min(0.9, eyeCenterY / max(1, geo.size.height))))

                ZStack {
                    // Base Canvas: all layers except Eyes and Catchlights
                    Canvas { context, _ in
                        for layer in variant.layers where layer.name != "Eyes" && layer.name != "Catchlights" {
                            let scaledPath = layer.path
                                .applying(CGAffineTransform(scaleX: scale, y: scale))
                                .offsetBy(dx: offsetX, dy: offsetY)
                            let color = LambVariantStore.resolveColor(key: layer.fillKey)
                            context.fill(scaledPath, with: .color(color))
                        }
                    }

                    // Eye Overlay Canvas: Eyes and Catchlights with blink keyframes
                    Canvas { context, _ in
                        for layer in variant.layers where layer.name == "Eyes" || layer.name == "Catchlights" {
                            let scaledPath = layer.path
                                .applying(CGAffineTransform(scaleX: scale, y: scale))
                                .offsetBy(dx: offsetX, dy: offsetY)
                            let color = LambVariantStore.resolveColor(key: layer.fillKey)
                            context.fill(scaledPath, with: .color(color))
                        }
                    }
                    .keyframeAnimator(initialValue: 1.0, trigger: blinkTick) { content, blink in
                        content.scaleEffect(y: blink, anchor: eyeAnchor)
                    } keyframes: { _ in
                        KeyframeTrack {
                            LinearKeyframe(0.1, duration: 0.09)
                            LinearKeyframe(1.0, duration: 0.09)
                        }
                    }
                }
            }
            .frame(
                width: displayHeight.map { $0 * (variant.viewBox.width / variant.viewBox.height) },
                height: displayHeight
            )
            .aspectRatio(variant.viewBox.width / variant.viewBox.height, contentMode: .fit)
            .task {
                guard !reduceMotion && enableBlink && expression != .sleepy else { return }
                while !Task.isCancelled {
                    try? await Task.sleep(nanoseconds: UInt64(Double.random(in: 4.0...6.0) * 1_000_000_000))
                    blinkTick += 1
                }
            }
        } else {
            // Fallback placeholder during cold loading
            Image(systemName: "sparkles")
                .foregroundStyle(ShepherdTheme.accent)
        }
    }
}

// MARK: - Lamb Avatar View (56pt head & shoulders pre-cut circle)

public struct LambAvatarView: View {
    public let stage: Int
    public let expression: LambExpression
    public var size: CGFloat = 56

    public init(stage: Int = 1, expression: LambExpression = .idle, size: CGFloat = 56) {
        self.stage = max(1, min(5, stage))
        self.expression = expression
        self.size = size
    }

    public var body: some View {
        let key = avatarKey(stage: stage, expression: expression)
        if let avatar = LambVariantStore.shared.avatar(key: key) {
            Canvas { context, canvasSize in
                let scale = canvasSize.width / avatar.width
                for layer in avatar.layers {
                    let scaledPath = layer.path
                        .applying(CGAffineTransform(scaleX: scale, y: scale))
                    let color = LambVariantStore.resolveColor(key: layer.fillKey)
                    context.fill(scaledPath, with: .color(color))
                }
            }
            .frame(width: size, height: size)
            .clipShape(Circle())
        } else {
            // Fallback to scaled full lamb
            LambView(stage: stage, expression: expression, displayHeight: size)
                .frame(width: size, height: size)
                .clipShape(Circle())
        }
    }

    private func avatarKey(stage: Int, expression: LambExpression) -> String {
        if stage == 1 {
            switch expression {
            case .happy: return "S1/Happy"
            case .encouraging: return "S1/Encouraging"
            default: return "S1/Idle"
            }
        }
        return "S\(stage)/Idle"
    }
}

// MARK: - Lamb Tab Icon Glyph (24x24 template image / shape)

public struct LambGlyph: View {
    public var size: CGFloat = 24

    public init(size: CGFloat = 24) {
        self.size = size
    }

    public var body: some View {
        if let glyphPath = LambVariantStore.shared.glyphPath {
            let vb = LambVariantStore.shared.glyphViewBox
            Canvas { context, canvasSize in
                let scale = min(canvasSize.width / vb.width, canvasSize.height / vb.height)
                let offsetX = (canvasSize.width - vb.width * scale) / 2.0 - vb.minX * scale
                let offsetY = (canvasSize.height - vb.height * scale) / 2.0 - vb.minY * scale

                let scaledPath = glyphPath
                    .applying(CGAffineTransform(scaleX: scale, y: scale))
                    .offsetBy(dx: offsetX, dy: offsetY)

                context.fill(scaledPath, with: .foreground)
            }
            .frame(width: size, height: size)
        } else {
            Image(systemName: "sun.min.fill")
                .frame(width: size, height: size)
        }
    }
}

// MARK: - Animated Lamb View with Motion Table Animations

public struct AnimatedLambView: View {
    public let stage: Int
    public let expression: LambExpression
    public var displayHeight: CGFloat?
    public var isBreathing: Bool = true
    public var hopTrigger: Int = 0
    public var isTilted: Bool = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var sparkle1Scale: CGFloat = 0.0
    @State private var sparkle2Scale: CGFloat = 0.0
    @State private var sparkle3Scale: CGFloat = 0.0

    public init(
        stage: Int = 1,
        expression: LambExpression = .idle,
        displayHeight: CGFloat? = nil,
        isBreathing: Bool = true,
        hopTrigger: Int = 0,
        isTilted: Bool = false
    ) {
        self.stage = stage
        self.expression = expression
        self.displayHeight = displayHeight
        self.isBreathing = isBreathing
        self.hopTrigger = hopTrigger
        self.isTilted = isTilted
    }

    public var body: some View {
        if reduceMotion {
            ZStack {
                LambView(stage: stage, expression: expression, displayHeight: displayHeight, enableBlink: false)
                if expression == .celebrating {
                    sparklesOverlayStatic
                }
            }
            .transition(.opacity)
        } else {
            ZStack {
                LambView(stage: stage, expression: expression, displayHeight: displayHeight)
                    // Row 4: Encouraging tilt (.rotationEffect 0 -> 10° with .spring(duration: 0.4, bounce: 0.2))
                    .rotationEffect(isTilted ? .degrees(10) : .zero)
                    .animation(ShepherdTheme.tiltSpring, value: isTilted)
                    // Row 1: Idle breathe loop (3.2s loop, easeInOut duration 1.6s per phase)
                    .phaseAnimator([0.0, 1.0]) { lamb, phase in
                        lamb.scaleEffect(x: 1.0, y: isBreathing ? 1.0 + 0.02 * phase : 1.0, anchor: .bottom)
                    } animation: { _ in
                        .easeInOut(duration: 1.6)
                    }
                    .modifier(HopAnimationModifier(expression: expression, hopTrigger: hopTrigger))

                // Row 5: Celebrate sparkles overlay
                if expression == .celebrating {
                    sparklesOverlayAnimated
                }
            }
        }
    }

    @ViewBuilder
    private var sparklesOverlayAnimated: some View {
        let h = displayHeight ?? 140
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: h * 0.12, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .scaleEffect(sparkle1Scale)
                .offset(x: -h * 0.45, y: -h * 0.35)

            Image(systemName: "sparkle")
                .font(.system(size: h * 0.16, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .scaleEffect(sparkle2Scale)
                .offset(x: 0, y: -h * 0.5)

            Image(systemName: "sparkle")
                .font(.system(size: h * 0.13, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .scaleEffect(sparkle3Scale)
                .offset(x: h * 0.45, y: -h * 0.38)
        }
        .task {
            withAnimation(.easeInOut(duration: 0.35)) { sparkle1Scale = 1.0 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { sparkle2Scale = 1.0 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { sparkle3Scale = 1.0 }
            try? await Task.sleep(nanoseconds: 400_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { sparkle1Scale = 0.0 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { sparkle2Scale = 0.0 }
            try? await Task.sleep(nanoseconds: 80_000_000)
            withAnimation(.easeInOut(duration: 0.35)) { sparkle3Scale = 0.0 }
        }
    }

    @ViewBuilder
    private var sparklesOverlayStatic: some View {
        let h = displayHeight ?? 140
        ZStack {
            Image(systemName: "sparkle")
                .font(.system(size: h * 0.12, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .offset(x: -h * 0.45, y: -h * 0.35)

            Image(systemName: "sparkle")
                .font(.system(size: h * 0.16, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .offset(x: 0, y: -h * 0.5)

            Image(systemName: "sparkle")
                .font(.system(size: h * 0.13, weight: .bold))
                .foregroundStyle(ShepherdTheme.accentFill)
                .offset(x: h * 0.45, y: -h * 0.38)
        }
    }

    struct HopState {
        var y: CGFloat = 0
        var squash: CGFloat = 1.0
    }
}

private struct HopAnimationModifier: ViewModifier {
    let expression: LambExpression
    let hopTrigger: Int

    func body(content: Content) -> some View {
        if expression == .celebrating {
            content.keyframeAnimator(initialValue: AnimatedLambView.HopState(), trigger: hopTrigger) { lamb, hop in
                lamb.offset(y: hop.y)
                    .scaleEffect(x: 1.0, y: hop.squash, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(-12, duration: 0.15)
                    SpringKeyframe(0, duration: 0.2, spring: .snappy)
                    CubicKeyframe(-12, duration: 0.15)
                    SpringKeyframe(0, duration: 0.2, spring: .snappy)
                }
                KeyframeTrack(\.squash) {
                    LinearKeyframe(1.0, duration: 0.33)
                    LinearKeyframe(0.94, duration: 0.06)
                    LinearKeyframe(1.0, duration: 0.10)
                    LinearKeyframe(1.0, duration: 0.21)
                    LinearKeyframe(0.94, duration: 0.06)
                    LinearKeyframe(1.0, duration: 0.10)
                }
            }
        } else {
            content.keyframeAnimator(initialValue: AnimatedLambView.HopState(), trigger: hopTrigger) { lamb, hop in
                lamb.offset(y: hop.y)
                    .scaleEffect(x: 1.0, y: hop.squash, anchor: .bottom)
            } keyframes: { _ in
                KeyframeTrack(\.y) {
                    CubicKeyframe(-12, duration: 0.15)
                    SpringKeyframe(0, duration: 0.2, spring: .snappy)
                }
                KeyframeTrack(\.squash) {
                    LinearKeyframe(1.0, duration: 0.33)
                    LinearKeyframe(0.94, duration: 0.06)
                    LinearKeyframe(1.0, duration: 0.10)
                }
            }
        }
    }
}

