import SwiftUI

/// How segment seams are treated — composes with the material (glass/standard)
/// to give three distinct looks:
/// - `.blended` + glass  → one shared container; bands melt into a smooth
///   color-zone ring (trimesters as soft gradient zones, no visible seams).
/// - `.divided` + glass  → each segment its own glass capsule with a gap between
///   (glassy *and* crisply sectioned).
/// - `.divided` + standard → crisp gradient strokes with gaps (the boldest seams).
public enum SegmentSeam: String, CaseIterable, Sendable {
    case blended
    case divided
}

/// A ring divided into proportional arcs — the radial sibling of `SegmentedBar`.
/// Each `ProgressSegment` becomes its own sub-arc (sized by `fraction`); a single
/// `fillFraction` sweeps across them all, just like the linear bar. Dividers are
/// angular *gaps* between segments (cleaner than radial lines and glass-friendly).
/// Glass or gradient body, mirroring `ProgressRing`. Data-driven: it knows nothing
/// about trimesters — a factory supplies the segments.
public struct SegmentedRing<Center: View>: View {
    public var segments: [ProgressSegment]
    public var fillFraction: Double
    public var lineWidth: CGFloat
    public var span: ArcSpan
    public var trackColor: Color
    public var style: ProgressStyle
    public var dividers: Bool
    public var gapDegrees: Double
    public var seam: SegmentSeam
    public var indicator: PositionIndicator
    public var center: () -> Center

    public init(segments: [ProgressSegment],
                fillFraction: Double,
                lineWidth: CGFloat = 12,
                span: ArcSpan = .full,
                trackColor: Color = Color.gray.opacity(0.2),
                style: ProgressStyle = .glass,
                dividers: Bool = true,
                gapDegrees: Double = 3,
                seam: SegmentSeam = .blended,
                indicator: PositionIndicator = .none,
                @ViewBuilder center: @escaping () -> Center) {
        self.segments = segments
        self.fillFraction = fillFraction
        self.lineWidth = lineWidth
        self.span = span
        self.trackColor = trackColor
        self.style = style
        self.dividers = dividers
        self.gapDegrees = gapDegrees
        self.seam = seam
        self.indicator = indicator
        self.center = center
    }

    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var effectiveAnimation: Animation? { reduceMotion ? nil : style.animation }
    private var fraction: Double { min(max(fillFraction, 0), 1) }
    private var stroke: StrokeStyle { StrokeStyle(lineWidth: lineWidth, lineCap: style.lineCap) }
    private var totalSweep: Double { span.end.degrees - span.start.degrees }
    private var gap: Double { dividers ? gapDegrees : 0 }

    /// Segments paired with their cumulative start fraction.
    private var laidOut: [(seg: ProgressSegment, start: Double)] {
        var cum = 0.0
        return segments.map { s in defer { cum += s.fraction }; return (s, cum) }
    }

    /// The angular sub-span a segment occupies, inset by half the gap each side.
    private func subSpan(start: Double, frac: Double) -> ArcSpan {
        let a = span.start.degrees + start * totalSweep + gap / 2
        let b = span.start.degrees + (start + frac) * totalSweep - gap / 2
        return ArcSpan(start: .degrees(a), end: .degrees(max(b, a)))
    }

    /// How much of *this* segment is filled, given the overall fill.
    private func filled(start: Double, frac: Double) -> Double {
        guard frac > 0 else { return 0 }
        return min(max((fraction - start) / frac, 0), 1)
    }

    /// A fill painted *along* its sub-arc (so a gradient runs start→end of the segment).
    private func arcStyle(_ fill: ProgressFill, _ sub: ArcSpan) -> AnyShapeStyle {
        switch fill {
        case .solid(let c):
            return AnyShapeStyle(c)
        case .linear(let cs), .angular(let cs):
            return AnyShapeStyle(AngularGradient(gradient: Gradient(colors: cs),
                                                 center: .center,
                                                 startAngle: sub.start, endAngle: sub.end))
        }
    }

    private func trackStyle(_ seg: ProgressSegment, _ sub: ArcSpan) -> AnyShapeStyle {
        switch style.unfilled {
        case .neutral:
            return AnyShapeStyle(trackColor)
        case .shade(let lighten, let opacity, _):
            let l = colorScheme == .dark ? lighten : lighten * 0.45
            return arcStyle(seg.fill.track(lighten: l, opacity: opacity), sub)
        }
    }

    /// Lead color of whichever segment the fill edge currently sits in.
    private var headColor: Color {
        for (seg, start) in laidOut where fraction <= start + seg.fraction {
            return seg.fill.leadColor
        }
        return segments.last?.fill.leadColor ?? .accentColor
    }

    @ViewBuilder private var content: some View {
        if style.glass { glassBody } else { standardBody }
    }

    public var body: some View {
        content.overlay(
            RingHead(indicator: indicator, fraction: fraction, span: span,
                     lineWidth: lineWidth, glowColor: headColor)
                .animation(effectiveAnimation, value: fraction)
        )
    }

    private var standardBody: some View {
        ZStack {
            ForEach(laidOut, id: \.seg.id) { (seg, start) in
                let sub = subSpan(start: start, frac: seg.fraction)
                ArcShape(span: sub, lineWidth: lineWidth)
                    .stroke(trackStyle(seg, sub), style: stroke)
                ArcShape(span: sub, lineWidth: lineWidth)
                    .trim(from: 0, to: filled(start: start, frac: seg.fraction))
                    .stroke(arcStyle(seg.fill, sub), style: stroke)
            }
            center()
        }
        .animation(effectiveAnimation, value: fraction)
    }

    /// One segment's glass bands (track + tinted fill) over its sub-span.
    @ViewBuilder
    private func glassBands(_ seg: ProgressSegment, start: Double) -> some View {
        let sub = subSpan(start: start, frac: seg.fraction)
        Color.clear
            .glassEffect(.regular, in: RingBand(span: sub, lineWidth: lineWidth, fraction: 1))
        Color.clear
            .glassEffect(.regular.tint(seg.fill.leadColor),
                         in: RingBand(span: sub, lineWidth: lineWidth,
                                      fraction: filled(start: start, frac: seg.fraction)))
    }

    /// Liquid Glass. `.blended` shares one container so the bands melt into a
    /// smooth color-zone ring; `.divided` gives each segment its own container so
    /// the seams survive as gaps between glass capsules.
    @ViewBuilder
    private var glassBody: some View {
        switch seam {
        case .blended:
            GlassEffectContainer {
                ZStack {
                    ForEach(laidOut, id: \.seg.id) { (seg, start) in
                        glassBands(seg, start: start)
                    }
                    center()
                }
                .animation(effectiveAnimation, value: fraction)
            }
        case .divided:
            ZStack {
                ForEach(laidOut, id: \.seg.id) { (seg, start) in
                    GlassEffectContainer { glassBands(seg, start: start) }
                }
                center()
            }
            .animation(effectiveAnimation, value: fraction)
        }
    }
}

public extension SegmentedRing where Center == EmptyView {
    init(segments: [ProgressSegment],
         fillFraction: Double,
         lineWidth: CGFloat = 12,
         span: ArcSpan = .full,
         trackColor: Color = Color.gray.opacity(0.2),
         style: ProgressStyle = .glass,
         dividers: Bool = true,
         gapDegrees: Double = 3,
         seam: SegmentSeam = .blended,
         indicator: PositionIndicator = .none) {
        self.init(segments: segments, fillFraction: fillFraction, lineWidth: lineWidth,
                  span: span, trackColor: trackColor, style: style, dividers: dividers,
                  gapDegrees: gapDegrees, seam: seam, indicator: indicator) { EmptyView() }
    }
}
