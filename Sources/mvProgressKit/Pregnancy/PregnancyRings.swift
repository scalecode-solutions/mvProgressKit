import SwiftUI

/// The three nested metrics.
public enum RingMetric: String, CaseIterable, Sendable {
    case pregnancy   // whole 280-day journey
    case phase       // progress through the current trimester / Labor Ready
    case week        // progress through the current week
}

/// How the three metrics map onto outer→inner rings. A flag, not a fork —
/// the renderer is identical; only the order changes.
public enum RingArrangement: String, CaseIterable, Sendable {
    /// A — scope shrinks inward: pregnancy (outer) · phase · week (inner).
    case containment
    /// B — immediate outermost: week (outer) · phase · pregnancy (inner).
    case recency
    /// C — 280-day clock as the spine; phase + week march around it.
    case timelineCore

    /// Metrics ordered outer → inner.
    public var order: [RingMetric] {
        switch self {
        case .containment:  return [.pregnancy, .phase, .week]
        case .recency:      return [.week, .phase, .pregnancy]
        case .timelineCore: return [.week, .pregnancy, .phase]
        }
    }
}

/// Where a ring's color comes from.
public enum RingColoring: String, CaseIterable, Sendable {
    /// Each metric keeps a fixed identity hue (pregnancy deepest → week lightest)
    /// regardless of position. Good when a legend identifies the rings.
    case byMetric
    /// The outer ring is always deepest, shading lighter inward — so every
    /// arrangement reads equally bold. Good when there's no legend.
    case byRadius
}

/// Builds concentric ring values from one pregnancy input. Mirrors
/// `PregnancyBarData`: domain logic here, generic `MultiRing` stays dumb.
public enum PregnancyRingData {
    public static func rings(for input: PregnancyBarInput,
                             arrangement: RingArrangement = .containment,
                             coloring: RingColoring = .byRadius) -> [RingValue] {
        let palette = PregnancyPalette.forGender(input.gender)
        let weeks = Double(input.completedWeeks) + Double(input.dayOfWeek) / 7.0

        func fraction(_ metric: RingMetric) -> Double {
            switch metric {
            case .pregnancy:
                return clamp(input.progressPercent / 100.0)
            case .phase:
                let (start, end) = phaseRange(input.phase)
                return clamp((weeks - start) / (end - start))
            case .week:
                return clamp(Double(input.dayOfWeek) / 7.0)
            }
        }

        func metricStops(_ metric: RingMetric) -> [Color] {
            switch metric {
            case .pregnancy: return palette.trimester3
            case .phase:     return palette.trimester2
            case .week:      return palette.trimester1
            }
        }

        // Outer → inner: deepest → lightest.
        let radiusStops = [palette.trimester3, palette.trimester2, palette.trimester1]

        return arrangement.order.enumerated().map { index, metric in
            let stops = coloring == .byRadius ? radiusStops[index] : metricStops(metric)
            return RingValue(id: index, fillFraction: fraction(metric), fill: .linear(stops))
        }
    }

    static func phaseRange(_ phase: PregnancyPhase) -> (Double, Double) {
        switch phase {
        case .first:      return (0, 14)
        case .second:     return (14, 28)
        case .third:      return (28, 37)
        case .laborReady: return (37, 42)
        }
    }

    private static func clamp(_ x: Double) -> Double { min(max(x, 0), 1) }
}

/// "Pregnancy at a glance" — nested rings with an adaptive center week readout
/// (the label scales to the clear inner hole so it never overlaps the rings).
public struct PregnancyRings: View {
    public var input: PregnancyBarInput
    public var arrangement: RingArrangement
    public var coloring: RingColoring
    public var style: ProgressStyle
    public var lineWidth: CGFloat
    public var spacing: CGFloat

    public init(input: PregnancyBarInput,
                arrangement: RingArrangement = .containment,
                coloring: RingColoring = .byRadius,
                style: ProgressStyle = .shaded,
                lineWidth: CGFloat = 12,
                spacing: CGFloat = 4) {
        self.input = input
        self.arrangement = arrangement
        self.coloring = coloring
        self.style = style
        self.lineWidth = lineWidth
        self.spacing = spacing
    }

    public var body: some View {
        GeometryReader { geo in
            let size = min(geo.size.width, geo.size.height)
            let band = 3 * lineWidth + 2 * spacing          // three strokes + two gaps
            let innerDiameter = max(size - 2 * band, 28)
            ZStack {
                MultiRing(rings: PregnancyRingData.rings(for: input,
                                                         arrangement: arrangement,
                                                         coloring: coloring),
                          lineWidth: lineWidth, spacing: spacing, style: style)
                VStack(spacing: 0) {
                    Text("\(input.completedWeeks)")
                        .font(.system(size: innerDiameter * 0.42, weight: .bold))
                        .monospacedDigit()
                    Text("weeks")
                        .font(.system(size: innerDiameter * 0.16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .frame(width: innerDiameter)
                .minimumScaleFactor(0.6)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(input.weekLabelText), \(input.daysSummary)")
        }
    }
}
