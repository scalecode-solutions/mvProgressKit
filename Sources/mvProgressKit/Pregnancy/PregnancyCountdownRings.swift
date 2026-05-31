import SwiftUI

/// The drop-in pregnancy countdown hero — the ring-world twin of
/// `PregnancyInfoCard`. A single bold **segmented trimester ring** (the journey,
/// at a glance) haloing a big **days-to-go** count, with the heart riding the
/// fill edge and a demoted "Week 37 · 3rd · Due Jun 19" meta line beneath.
///
/// Opinionated by design (unlike the bare ring primitives): the center is
/// populated and the heart is on by default, because being the complete hero is
/// its whole job — there's nothing around it to duplicate. Chrome-less: the host
/// wraps it in its own card surface.
public struct PregnancyCountdownRings: View {
    public var input: PregnancyBarInput
    public var style: ProgressStyle
    public var seam: SegmentSeam
    public var center: RingCenter
    public var indicator: PositionIndicator
    public var showMeta: Bool
    public var diameter: CGFloat
    public var lineWidth: CGFloat

    public init(input: PregnancyBarInput,
                style: ProgressStyle = .glass,
                seam: SegmentSeam = .blended,
                center: RingCenter = .daysToDue,
                indicator: PositionIndicator = .symbol("heart.fill"),
                showMeta: Bool = true,
                diameter: CGFloat = 180,
                lineWidth: CGFloat = 20) {
        self.input = input
        self.style = style
        self.seam = seam
        self.center = center
        self.indicator = indicator
        self.showMeta = showMeta
        self.diameter = diameter
        self.lineWidth = lineWidth
    }

    private var palette: PregnancyPalette { .forGender(input.gender) }
    private var accent: Color { palette.trimesterLead(input.trimesterNumber) }
    private var pregFraction: Double { min(max(input.weeksContinuous / 40.0, 0), 1) }

    /// Trimester arcs, proportional to real lengths (14 · 14 · 12 weeks).
    private var segments: [ProgressSegment] {
        [
            ProgressSegment(id: 0, fraction: 14.0 / 40.0, fill: .linear(palette.trimester1)),
            ProgressSegment(id: 1, fraction: 14.0 / 40.0, fill: .linear(palette.trimester2)),
            ProgressSegment(id: 2, fraction: 12.0 / 40.0, fill: .linear(palette.trimester3)),
        ]
    }

    private var dueShort: String? {
        guard let due = input.dueDate else { return nil }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: due)
    }

    public var body: some View {
        let inner = max(diameter - 2 * lineWidth, 28)
        VStack(spacing: 12) {
            SegmentedRing(segments: segments, fillFraction: pregFraction,
                          lineWidth: lineWidth, style: style, seam: seam,
                          indicator: indicator) {
                if let c = center.content(for: input) {
                    RingCenterLabel(value: c.value, caption: c.caption,
                                    diameter: inner, valueColor: accent)
                }
            }
            .frame(width: diameter, height: diameter)

            if showMeta { metaLine }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(input.daysSummary). \(input.weekLabelText). \(input.trimesterName).")
    }

    private var metaLine: some View {
        HStack(spacing: 6) {
            Text(input.weekLabelText)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.secondary)
            Text(input.trimesterOrdinal)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(Capsule().fill(accent))
            if let due = dueShort {
                Text("Due \(due)")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
