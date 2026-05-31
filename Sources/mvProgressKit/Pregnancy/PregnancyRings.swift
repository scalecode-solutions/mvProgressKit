import SwiftUI

/// Builds concentric ring values from one pregnancy input — three nested views
/// of the same timeline, each a finer division of the one outside it:
///   outer = whole pregnancy · middle = current phase · inner = current week.
/// Mirrors `PregnancyBarData`: domain logic here, generic `MultiRing` stays dumb.
public enum PregnancyRingData {
    public static func rings(for input: PregnancyBarInput) -> [RingValue] {
        let palette = PregnancyPalette.forGender(input.gender)
        let weeks = Double(input.completedWeeks) + Double(input.dayOfWeek) / 7.0

        // Outer — whole pregnancy (0→40 weeks / 280 days).
        let overall = clamp(input.progressPercent / 100.0)

        // Middle — progress through the current phase.
        let (start, end) = phaseRange(input.phase)
        let phase = clamp((weeks - start) / (end - start))

        // Inner — progress through the current week.
        let week = clamp(Double(input.dayOfWeek) / 7.0)

        return [
            RingValue(id: 0, fillFraction: overall, fill: .linear(palette.trimester3)),
            RingValue(id: 1, fillFraction: phase,   fill: .linear(palette.trimester2)),
            RingValue(id: 2, fillFraction: week,    fill: .linear(palette.trimester1)),
        ]
    }

    /// Phase week bounds — boundaries match `PregnancyPhase`. Labor Ready runs
    /// 37→42 so it has room for overtime and caps cleanly.
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

/// "Pregnancy at a glance" — the nested rings with a center week readout.
/// A ready Clingy dashboard element, not just a demo prop.
public struct PregnancyRings: View {
    public var input: PregnancyBarInput
    public var lineWidth: CGFloat
    public var spacing: CGFloat

    public init(input: PregnancyBarInput, lineWidth: CGFloat = 12, spacing: CGFloat = 4) {
        self.input = input
        self.lineWidth = lineWidth
        self.spacing = spacing
    }

    public var body: some View {
        ZStack {
            MultiRing(rings: PregnancyRingData.rings(for: input),
                      lineWidth: lineWidth, spacing: spacing)
            VStack(spacing: 0) {
                Text("\(input.completedWeeks)")
                    .font(.system(size: 30, weight: .bold))
                    .monospacedDigit()
                Text("weeks")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
