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
    public var center: () -> Center

    public init(fillFraction: Double,
                fill: ProgressFill,
                lineWidth: CGFloat = 12,
                trackColor: Color = Color.gray.opacity(0.2),
                span: ArcSpan = .full,
                style: ProgressStyle = .glass,
                @ViewBuilder center: @escaping () -> Center) {
        self.fillFraction = fillFraction
        self.fill = fill
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.span = span
        self.style = style
        self.center = center
    }

    private var fraction: Double { min(max(fillFraction, 0), 1) }
    private var stroke: StrokeStyle { StrokeStyle(lineWidth: lineWidth, lineCap: style.lineCap) }

    public var body: some View {
        ZStack {
            ArcShape(span: span, lineWidth: lineWidth)
                .stroke(trackColor, style: stroke)
            ArcShape(span: span, lineWidth: lineWidth)
                .trim(from: 0, to: fraction)
                .stroke(fill.radialStyle(), style: stroke)
                .modifier(AnimateRing(animation: style.animation, value: fraction))
            center()
        }
    }
}

public extension ProgressRing where Center == EmptyView {
    init(fillFraction: Double,
         fill: ProgressFill,
         lineWidth: CGFloat = 12,
         trackColor: Color = Color.gray.opacity(0.2),
         span: ArcSpan = .full,
         style: ProgressStyle = .glass) {
        self.init(fillFraction: fillFraction, fill: fill, lineWidth: lineWidth,
                  trackColor: trackColor, span: span, style: style) { EmptyView() }
    }
}

private struct AnimateRing: ViewModifier, @unchecked Sendable {
    let animation: Animation?
    let value: Double
    func body(content: Content) -> some View {
        if let animation { content.animation(animation, value: value) } else { content }
    }
}
