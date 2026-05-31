import SwiftUI

/// Sweep of a radial track. `ProgressRing` uses `.full`; `Gauge` uses a partial
/// span — same renderer, different angles. This is the seam that keeps a gauge
/// from being a separate component later.
public struct ArcSpan: Equatable, Sendable {
    public var start: Angle
    public var end: Angle
    public init(start: Angle, end: Angle) {
        self.start = start
        self.end = end
    }
    /// Full circle, starting at 12 o'clock, clockwise.
    public static let full = ArcSpan(start: .degrees(-90), end: .degrees(270))
    /// 270° sweep with the gap at the bottom (classic gauge).
    public static let gauge = ArcSpan(start: .degrees(135), end: .degrees(405))
}

/// An arc from `span.start` to `span.end`, inset so a stroke of `lineWidth`
/// fits inside the frame. `.trim(from:to:)` on this gives radial progress.
public struct ArcShape: Shape {
    public var span: ArcSpan
    public var lineWidth: CGFloat
    public init(span: ArcSpan, lineWidth: CGFloat) {
        self.span = span
        self.lineWidth = lineWidth
    }
    public func path(in rect: CGRect) -> Path {
        let radius = (min(rect.width, rect.height) - lineWidth) / 2
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY),
                    radius: radius,
                    startAngle: span.start,
                    endAngle: span.end,
                    clockwise: false)
        return path
    }
}

/// Circular (or partial-arc) progress with a gradient stroke and an optional
/// center view. The nursery category ring is `ProgressRing` with a `.full`
/// span; `Gauge` is the partial-span sibling.
public struct ProgressRing<Center: View>: View {
    public var fillFraction: Double
    public var fill: ProgressFill
    public var lineWidth: CGFloat
    public var trackColor: Color
    public var span: ArcSpan
    public var style: ProgressStyle
    public var indicator: PositionIndicator
    public var center: () -> Center

    public init(fillFraction: Double,
                fill: ProgressFill,
                lineWidth: CGFloat = 12,
                trackColor: Color = Color.gray.opacity(0.2),
                span: ArcSpan = .full,
                style: ProgressStyle = .glass,
                indicator: PositionIndicator = .none,
                @ViewBuilder center: @escaping () -> Center) {
        self.fillFraction = fillFraction
        self.fill = fill
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.span = span
        self.style = style
        self.indicator = indicator
        self.center = center
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var effectiveAnimation: Animation? { reduceMotion ? nil : style.animation }

    private var fraction: Double { min(max(fillFraction, 0), 1) }
    private var stroke: StrokeStyle { StrokeStyle(lineWidth: lineWidth, lineCap: style.lineCap) }

    /// Track paint: neutral color, or a light shade of the fill (theme-aware).
    private var resolvedTrack: AnyShapeStyle {
        switch style.unfilled {
        case .neutral:
            return AnyShapeStyle(trackColor)
        case .shade(let lighten, let opacity, _):
            let l = colorScheme == .dark ? lighten : lighten * 0.45
            return AnyShapeStyle(fill.track(lighten: l, opacity: opacity).radialStyle())
        }
    }

    @ViewBuilder private var content: some View {
        if style.glass { glassBody } else { standardBody }
    }

    public var body: some View {
        content.overlay(
            RingHead(indicator: indicator, fraction: fraction, span: span,
                     lineWidth: lineWidth, glowColor: fill.leadColor)
                .modifier(AnimateRing(animation: effectiveAnimation, value: fraction))
        )
    }

    private var standardBody: some View {
        ZStack {
            ArcShape(span: span, lineWidth: lineWidth)
                .stroke(resolvedTrack, style: stroke)
            ArcShape(span: span, lineWidth: lineWidth)
                .trim(from: 0, to: fraction)
                .stroke(fill.radialStyle(), style: stroke)
                .modifier(AnimateRing(animation: effectiveAnimation, value: fraction))
            center()
        }
    }

    /// Liquid Glass ring: glass is clipped to a `RingBand` (the stroked arc as a
    /// fillable shape), since `glassEffect` needs a region, not a thin stroke.
    private var glassBody: some View {
        GlassEffectContainer {
            ZStack {
                Color.clear
                    .glassEffect(.regular, in: RingBand(span: span, lineWidth: lineWidth, fraction: 1))
                Color.clear
                    .glassEffect(.regular.tint(fill.leadColor),
                                 in: RingBand(span: span, lineWidth: lineWidth, fraction: fraction))
                    .modifier(AnimateRing(animation: effectiveAnimation, value: fraction))
                center()
            }
        }
    }
}

/// The stroked arc as a *filled* shape — lets `glassEffect(in:)` paint the ring
/// band as Liquid Glass (it can't apply to a thin stroke directly).
public struct RingBand: Shape {
    public var span: ArcSpan
    public var lineWidth: CGFloat
    public var fraction: Double
    public init(span: ArcSpan, lineWidth: CGFloat, fraction: Double) {
        self.span = span
        self.lineWidth = lineWidth
        self.fraction = fraction
    }
    public func path(in rect: CGRect) -> Path {
        let arc = ArcShape(span: span, lineWidth: lineWidth).path(in: rect)
        let trimmed = arc.trimmedPath(from: 0, to: CGFloat(min(max(fraction, 0), 1)))
        return trimmed.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .round))
    }
}

public extension ProgressRing where Center == EmptyView {
    init(fillFraction: Double,
         fill: ProgressFill,
         lineWidth: CGFloat = 12,
         trackColor: Color = Color.gray.opacity(0.2),
         span: ArcSpan = .full,
         style: ProgressStyle = .glass,
         indicator: PositionIndicator = .none) {
        self.init(fillFraction: fillFraction, fill: fill, lineWidth: lineWidth,
                  trackColor: trackColor, span: span, style: style,
                  indicator: indicator) { EmptyView() }
    }
}

/// The "you are here" head that rides a ring's leading edge — the radial cousin
/// of `SegmentedBar`'s position indicator. Placed at the arc point
/// `span.start + fraction·sweep`, with the same white-symbol + glow treatment.
/// Shows through `fraction == 1` (the countdown heart lands at 12 o'clock at term).
public struct RingHead: View {
    public var indicator: PositionIndicator
    public var fraction: Double
    public var span: ArcSpan
    public var lineWidth: CGFloat
    public var glowColor: Color

    public init(indicator: PositionIndicator, fraction: Double, span: ArcSpan,
                lineWidth: CGFloat, glowColor: Color) {
        self.indicator = indicator
        self.fraction = fraction
        self.span = span
        self.lineWidth = lineWidth
        self.glowColor = glowColor
    }

    public var body: some View {
        if indicator != .none, fraction > 0.02 {
            GeometryReader { geo in
                let r = (min(geo.size.width, geo.size.height) - lineWidth) / 2
                let sweep = span.end.degrees - span.start.degrees
                let a = (span.start.degrees + min(max(fraction, 0), 1) * sweep) * .pi / 180
                content
                    .shadow(color: glowColor.opacity(0.5), radius: lineWidth / 3)
                    .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                    .position(x: geo.size.width / 2 + r * cos(a),
                              y: geo.size.height / 2 + r * sin(a))
            }
        }
    }

    @ViewBuilder private var content: some View {
        switch indicator {
        case .none:
            EmptyView()
        case .dot:
            Circle()
                .fill(Color.white)
                .overlay(Circle().strokeBorder(Color.black.opacity(0.12), lineWidth: 0.5))
                .frame(width: lineWidth * 1.1, height: lineWidth * 1.1)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: lineWidth * 0.8, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}

private struct AnimateRing: ViewModifier, @unchecked Sendable {
    let animation: Animation?
    let value: Double
    func body(content: Content) -> some View {
        if let animation { content.animation(animation, value: value) } else { content }
    }
}
