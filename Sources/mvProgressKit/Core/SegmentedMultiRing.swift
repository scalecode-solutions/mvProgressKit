import SwiftUI

/// One ring's content in a `SegmentedMultiRing`: either a single fill or a
/// segmented arc. Carries an optional per-ring head indicator (so "heart on the
/// outer ring only" is just that ring's flag).
public struct RingContent {
    public enum Kind {
        case fill(RingValue)
        case segmented(segments: [ProgressSegment], fillFraction: Double)
    }
    public var kind: Kind
    public var indicator: PositionIndicator

    public init(kind: Kind, indicator: PositionIndicator = .none) {
        self.kind = kind
        self.indicator = indicator
    }

    /// A single-fill ring.
    public static func fill(_ value: RingValue,
                            indicator: PositionIndicator = .none) -> RingContent {
        RingContent(kind: .fill(value), indicator: indicator)
    }

    /// A segmented ring (proportional arcs).
    public static func segmented(segments: [ProgressSegment],
                                 fillFraction: Double,
                                 indicator: PositionIndicator = .none) -> RingContent {
        RingContent(kind: .segmented(segments: segments, fillFraction: fillFraction),
                    indicator: indicator)
    }
}

/// Concentric rings where each ring is independently a single fill **or** a
/// segmented arc — the heterogeneous sibling of `MultiRing`. Any mix works
/// (segmented inner + fill outers, fill inner + segmented outer, …); the
/// component is the superset, `MultiRing` is the all-fill subset, so reach for
/// this whenever *at least one* ring is segmented.
///
/// The segment-style flags (`seam`, `gapDegrees`, `dividers`) forward to the
/// segmented rings; fill rings ignore them. Keeps all the heterogeneous-stacking
/// complexity in one testable component — `MultiRing` never learns any of it.
public struct SegmentedMultiRing: View {
    public var rings: [RingContent]      // outer → inner
    public var lineWidth: CGFloat
    public var spacing: CGFloat
    public var trackColor: Color
    public var style: ProgressStyle
    public var seam: SegmentSeam
    public var gapDegrees: Double
    public var dividers: Bool

    public init(rings: [RingContent],
                lineWidth: CGFloat = 12,
                spacing: CGFloat = 4,
                trackColor: Color = Color.gray.opacity(0.2),
                style: ProgressStyle = .glass,
                seam: SegmentSeam = .blended,
                gapDegrees: Double = 3,
                dividers: Bool = true) {
        self.rings = rings
        self.lineWidth = lineWidth
        self.spacing = spacing
        self.trackColor = trackColor
        self.style = style
        self.seam = seam
        self.gapDegrees = gapDegrees
        self.dividers = dividers
    }

    public var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.offset) { index, ring in
                ringView(ring)
                    .padding(CGFloat(index) * (lineWidth + spacing))
            }
        }
    }

    @ViewBuilder
    private func ringView(_ ring: RingContent) -> some View {
        switch ring.kind {
        case .fill(let value):
            ProgressRing(fillFraction: value.fillFraction, fill: value.fill,
                         lineWidth: lineWidth, trackColor: trackColor,
                         span: .full, style: style, indicator: ring.indicator)
        case .segmented(let segments, let fillFraction):
            // Segment-style flags forward here; fill rings above never see them.
            SegmentedRing(segments: segments, fillFraction: fillFraction,
                          lineWidth: lineWidth, span: .full, trackColor: trackColor,
                          style: style, dividers: dividers, gapDegrees: gapDegrees,
                          seam: seam, indicator: ring.indicator)
        }
    }
}
