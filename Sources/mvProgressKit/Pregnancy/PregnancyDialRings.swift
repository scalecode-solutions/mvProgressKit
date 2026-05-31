import SwiftUI

/// What the outer ("fastest-changing") ring counts.
public enum DialDayMode: String, CaseIterable, Sendable {
    /// Day of the current week (Mon→Sun) — a watch's day complication; resets weekly.
    case watch
    /// Day of pregnancy (day N of ~280) — the running calendar count.
    case calendar
}

/// "Nested time units" dial — concentric rings ruled in trimesters / weeks /
/// days, finest unit outermost (volatility outward). Built on `SegmentedMultiRing`:
/// the inner trimester ring is segmented; week + day are single fills.
///
/// - inner  = **trimester** — segmented into the three proportional arcs (14·14·12
///   weeks), filled to overall progress so it doubles as the whole-journey view.
/// - middle = **week within the current phase** (trimester / labor-ready).
/// - outer  = **day**, per `dayMode` (`.watch` = day-in-week · `.calendar` =
///   day-of-pregnancy).
///
/// A primitive: bare by default (`center`/`indicator` = `.none`). The host or a
/// hero wrapper opts into the center readout and the heart (which rides the
/// outer ring — the most volatile edge).
public struct PregnancyDialRings: View {
    public var input: PregnancyBarInput
    public var dayMode: DialDayMode
    public var style: ProgressStyle
    public var seam: SegmentSeam
    public var center: RingCenter
    public var indicator: PositionIndicator
    public var lineWidth: CGFloat
    public var spacing: CGFloat

    public init(input: PregnancyBarInput,
                dayMode: DialDayMode = .watch,
                style: ProgressStyle = .glass,
                seam: SegmentSeam = .blended,
                center: RingCenter = .none,
                indicator: PositionIndicator = .none,
                lineWidth: CGFloat = 14,
                spacing: CGFloat = 4) {
        self.input = input
        self.dayMode = dayMode
        self.style = style
        self.seam = seam
        self.center = center
        self.indicator = indicator
        self.lineWidth = lineWidth
        self.spacing = spacing
    }

    private var palette: PregnancyPalette { .forGender(input.gender) }

    /// Outer → inner ring contents built from the input.
    private var rings: [RingContent] {
        let weeks = input.weeksContinuous
        let pregFraction = min(max(weeks / 40.0, 0), 1)

        // Week within the current phase (trimester / labor-ready window).
        let (start, end) = PregnancyRingData.phaseRange(input.phase)
        let weekInPhase = end > start ? min(max((weeks - start) / (end - start), 0), 1) : 0

        // Outer day metric.
        let dayFraction: Double = dayMode == .watch
            ? Double(input.dayOfWeek) / 7.0
            : pregFraction   // .calendar: day-of-pregnancy ≡ weeks/40

        // Inner trimester arcs — proportional to real lengths (14 · 14 · 12 weeks).
        let triSegments = [
            ProgressSegment(id: 0, fraction: 14.0 / 40.0, fill: .linear(palette.trimester1)),
            ProgressSegment(id: 1, fraction: 14.0 / 40.0, fill: .linear(palette.trimester2)),
            ProgressSegment(id: 2, fraction: 12.0 / 40.0, fill: .linear(palette.trimester3)),
        ]

        return [
            // Outer: day — heart rides here when opted in.
            .fill(RingValue(id: 0, fillFraction: dayFraction, fill: .linear(palette.trimester3)),
                  indicator: indicator),
            // Middle: week within phase.
            .fill(RingValue(id: 1, fillFraction: weekInPhase, fill: .linear(palette.trimester2))),
            // Inner: trimester (segmented), filled to overall progress.
            .segmented(segments: triSegments, fillFraction: pregFraction),
        ]
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let band = 3 * lineWidth + 2 * spacing
            let innerDiameter = max(size - 2 * band, 28)
            ZStack {
                SegmentedMultiRing(rings: rings, lineWidth: lineWidth, spacing: spacing,
                                   style: style, seam: seam)
                if let c = center.content(for: input) {
                    RingCenterLabel(value: c.value, caption: c.caption, diameter: innerDiameter)
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(input.weekLabelText), \(input.daysSummary)")
    }
}
