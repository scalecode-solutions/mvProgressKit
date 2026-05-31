import SwiftUI
import mvProgressKit

/// One focused page per component — laid out to be fully visible in a single
/// screenshot. Driven by the shared `input`; rings page also reads `coloring`.
struct DetailPage: View {
    let screen: DemoScreen
    let input: PregnancyBarInput
    @Binding var coloring: RingColoring
    let style: ProgressStyle
    let overtimeStyle: OvertimeStyle
    let indicator: PositionIndicator
    let label: TimelineLabel
    let daysText: String?
    let center: RingCenter

    private func withIndicator(_ base: ProgressOverlays) -> ProgressOverlays {
        var o = base; o.indicator = indicator; return o
    }

    private var palette: PregnancyPalette { .forGender(input.gender) }
    private var deepFill: ProgressFill { .linear(palette.trimester3) }
    private var demoFraction: Double { min(max(input.progressPercent / 100.0, 0), 1) }
    private var stepsDone: Int { Int(demoFraction * 5) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch screen {
                case .infoCard:  infoCard
                case .timeline:  timeline
                case .rings:     rings
                case .segmented: segmented
                case .trackbar:  trackbar
                case .steps:     steps
                case .ring:      ring
                case .gauge:     gauge
                case .multiring: multiring
                case .segring:   segring
                case .dial:      dial
                case .ringhero:  ringhero
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(uiColor: .systemBackground))
    }

    // MARK: Pages

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 28) {
            labeled("standard · surface chrome") {
                PregnancyInfoCard(input: input, style: .standard, chrome: .surface,
                                  barStyle: style, overtimeStyle: overtimeStyle,
                                  indicator: indicator, daysText: daysText)
            }
            labeled("compact · surface chrome") {
                PregnancyInfoCard(input: input, style: .compact, chrome: .surface,
                                  barStyle: style, overtimeStyle: overtimeStyle,
                                  indicator: indicator, daysText: daysText)
            }
        }
    }

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 24) {
            labeled("standard · captioned (B)") { PregnancyTimelineBar(input: input, size: .standard, overlays: withIndicator(.captioned), style: style, overtimeStyle: overtimeStyle, label: label) }
            labeled("compact · captioned") { PregnancyTimelineBar(input: input, size: .compact, overlays: withIndicator(.captioned), style: style, overtimeStyle: overtimeStyle, label: label) }
            labeled("standard · inside (classic)") { PregnancyTimelineBar(input: input, size: .standard, overlays: withIndicator(.full), style: style, overtimeStyle: overtimeStyle, label: label) }
            labeled("lean · Prep landing") { PregnancyTimelineBar(input: input, size: .standard, overlays: withIndicator(.lean), style: style, overtimeStyle: overtimeStyle, label: label) }
            labeled("bare") { PregnancyTimelineBar(input: input, size: .standard, overlays: .bare, style: style, overtimeStyle: overtimeStyle, label: .none) }
        }
    }

    private var rings: some View {
        VStack(spacing: 20) {
            Picker("Coloring", selection: $coloring) {
                Text("by radius").tag(RingColoring.byRadius)
                Text("by metric").tag(RingColoring.byMetric)
            }
            .pickerStyle(.segmented)
            HStack(spacing: 16) {
                ringCell("A", "containment", .containment)
                ringCell("B", "recency", .recency)
            }
            HStack(spacing: 16) {
                ringCell("C", "timeline-core", .timelineCore)
                rawRingCell
            }
        }
    }

    private var segmented: some View {
        labeled("raw 3-segment bar + markers") {
            SegmentedBar(
                segments: [
                    ProgressSegment(id: 0, fraction: 0.4, fill: .linear([.green, .mint])),
                    ProgressSegment(id: 1, fraction: 0.35, fill: .linear([.blue, .cyan])),
                    ProgressSegment(id: 2, fraction: 0.25, fill: .linear([.purple, .pink])),
                ],
                markers: [
                    ProgressMarker(id: 0, position: 0.4, label: "A"),
                    ProgressMarker(id: 1, position: 0.75, label: "B"),
                ],
                fillFraction: demoFraction,
                size: .standard,
                style: style,
                overlays: ProgressOverlays(caption: .none, indicator: indicator,
                                           glow: true, markerTicks: true,
                                           markerLabels: false, dividers: true)
            )
        }
    }

    private var trackbar: some View {
        VStack(alignment: .leading, spacing: 24) {
            labeled("compact") { TrackBar(fillFraction: demoFraction, fill: deepFill, size: .compact, style: style) }
            labeled("standard") { TrackBar(fillFraction: demoFraction, fill: deepFill, size: .standard, style: style) }
        }
    }

    private var steps: some View {
        labeled("checklist sections") {
            StepIndicator(steps: stepMarkers, fill: deepFill).frame(height: 48)
        }
    }

    private var ring: some View {
        HStack(spacing: 28) {
            radial("with %") {
                ProgressRing(fillFraction: demoFraction, fill: deepFill, lineWidth: 16,
                             style: style, indicator: indicator) {
                    Text("\(Int(demoFraction * 100))%").font(.title2.bold())
                }
            }
            radial("bare") {
                ProgressRing(fillFraction: demoFraction, fill: deepFill, lineWidth: 16,
                             style: style, indicator: indicator)
            }
        }
        .frame(height: 200)
    }

    private var gauge: some View {
        radial("gauge · 270°") {
            ProgressGauge(fillFraction: demoFraction, fill: deepFill, lineWidth: 18, style: style) {
                VStack(spacing: 2) {
                    Text("\(input.completedWeeks)").font(.system(size: 40, weight: .bold))
                    Text("weeks").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .frame(height: 240)
    }

    // MARK: Ring-hero brainstorm (rings left, info right)

    private var dueLong: String {
        guard let d = input.dueDate else { return "—" }
        let f = DateFormatter(); f.dateFormat = "MMM d, yyyy"; return f.string(from: d)
    }
    private var dueShort: String {
        guard let d = input.dueDate else { return "—" }
        let f = DateFormatter(); f.dateFormat = "MMM d"; return f.string(from: d)
    }
    private var chipColor: Color { palette.trimesterLead(input.trimesterNumber) }

    private func heroChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10).padding(.vertical, 4)
            .background(Capsule().fill(chipColor))
    }

    private func heroCard<V: View>(_ label: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 22).fill(.regularMaterial))
                .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(Color.primary.opacity(0.08)))
        }
    }

    /// Small "Week 24 · 2nd · Due Jun 19" supporting line — week/day demoted.
    private var heroMetaLine: some View {
        HStack(spacing: 6) {
            Text(input.weekLabelText).font(.system(size: 13, weight: .medium)).foregroundStyle(.secondary)
            heroChip(input.trimesterOrdinal)
            Text("Due \(dueShort)").font(.system(size: 13)).foregroundStyle(.secondary)
        }
    }

    private var daysCaption: String { input.daysUntilDue < 0 ? "days overdue" : "days to go" }

    private var ringhero: some View {
        VStack(spacing: 22) {
            // The real drop-in component (#3, now shipped).
            heroCard("PregnancyCountdownRings · the drop-in") {
                HStack { Spacer(); PregnancyCountdownRings(input: input, style: style); Spacer() }
            }
            // Alt layout kept for comparison — rings left, days dominant right.
            heroCard("alt · rings left · days dominant") {
                HStack(spacing: 18) {
                    PregnancyDialRings(input: input, dayMode: .watch, style: style,
                                       center: .none, indicator: .symbol("heart.fill"), lineWidth: 11)
                        .frame(width: 116, height: 116)
                    VStack(alignment: .leading, spacing: 0) {
                        Text("\(abs(input.daysUntilDue))")
                            .font(.system(size: 56, weight: .bold)).foregroundStyle(chipColor)
                            .lineLimit(1).minimumScaleFactor(0.6)
                        Text(daysCaption)
                            .font(.system(size: 12, weight: .semibold)).kerning(0.5)
                            .textCase(.uppercase).foregroundStyle(.secondary)
                        Spacer().frame(height: 10)
                        heroMetaLine
                    }
                    Spacer()
                }
            }
        }
    }

    private var dial: some View {
        HStack(spacing: 16) {
            radial("watch · day-in-week") {
                PregnancyDialRings(input: input, dayMode: .watch, style: style,
                                   center: center, indicator: indicator)
                    .frame(width: 155, height: 155)
            }
            radial("calendar · day-of-pregnancy") {
                PregnancyDialRings(input: input, dayMode: .calendar, style: style,
                                   center: center, indicator: indicator)
                    .frame(width: 155, height: 155)
            }
        }
    }

    private var segring: some View {
        let weeks = min(max(input.weeksContinuous / 40.0, 0), 1)
        // Trimester arcs, proportional to real lengths (14 · 14 · 12 weeks).
        let triSegs = [
            ProgressSegment(id: 0, fraction: 14.0 / 40.0, fill: .linear(palette.trimester1), label: "1st"),
            ProgressSegment(id: 1, fraction: 14.0 / 40.0, fill: .linear(palette.trimester2), label: "2nd"),
            ProgressSegment(id: 2, fraction: 12.0 / 40.0, fill: .linear(palette.trimester3), label: "3rd"),
        ]
        func cell(_ title: String, _ st: ProgressStyle, _ seam: SegmentSeam, gap: Double) -> some View {
            radial(title) {
                SegmentedRing(segments: triSegs, fillFraction: weeks, lineWidth: 16,
                              style: st, dividers: true, gapDegrees: gap, seam: seam,
                              indicator: indicator)
                    .frame(width: 150, height: 150)
            }
        }
        return VStack(spacing: 24) {
            HStack(spacing: 16) {
                cell("blended glass", .glass, .blended, gap: 4)
                cell("divided glass", .glass, .divided, gap: 8)
            }
            cell("standard · gaps", .shaded, .divided, gap: 8)
        }
    }

    private var multiring: some View {
        let weeks = min(max(input.weeksContinuous / 40.0, 0), 1)
        let triSegs = [
            ProgressSegment(id: 0, fraction: 14.0 / 40.0, fill: .linear(palette.trimester1)),
            ProgressSegment(id: 1, fraction: 14.0 / 40.0, fill: .linear(palette.trimester2)),
            ProgressSegment(id: 2, fraction: 12.0 / 40.0, fill: .linear(palette.trimester3)),
        ]
        let (ps, pe): (Double, Double) = {
            switch input.phase {
            case .first:      return (0, 14)
            case .second:     return (14, 28)
            case .third:      return (28, 37)
            case .laborReady: return (37, 42)
            }
        }()
        let phaseFrac = min(max((input.weeksContinuous - ps) / (pe - ps), 0), 1)
        return VStack(spacing: 24) {
            radial("MultiRing · all fill") {
                MultiRing(rings: [
                    RingValue(id: 0, fillFraction: 0.9, fill: .linear(palette.trimester3)),
                    RingValue(id: 1, fillFraction: 0.6, fill: .linear(palette.trimester2)),
                    RingValue(id: 2, fillFraction: 0.4, fill: .linear(palette.trimester1)),
                ], lineWidth: 16, style: style)
                .frame(width: 180, height: 180)
            }
            radial("SegmentedMultiRing · day + week + trimester(seg)") {
                SegmentedMultiRing(rings: [
                    .fill(RingValue(id: 0, fillFraction: Double(input.dayOfWeek) / 7.0,
                                    fill: .linear(palette.trimester1)), indicator: indicator),
                    .fill(RingValue(id: 1, fillFraction: phaseFrac, fill: .linear(palette.trimester2))),
                    .segmented(segments: triSegs, fillFraction: weeks),
                ], lineWidth: 16, style: style, seam: .blended)
                .frame(width: 180, height: 180)
            }
        }
    }

    // MARK: Helpers

    private var stepMarkers: [ProgressMarker] {
        (0..<5).map { i in
            let state: NodeState = i < stepsDone ? .done : (i == stepsDone ? .active : .todo)
            return ProgressMarker(id: i, position: Double(i) / 4.0, label: "\(i + 1)", state: state)
        }
    }

    private func ringCell(_ tag: String, _ name: String, _ arrangement: RingArrangement) -> some View {
        VStack(spacing: 10) {
            PregnancyRings(input: input, arrangement: arrangement, coloring: coloring,
                           style: style, lineWidth: 13, spacing: 4, center: center)
                .frame(width: 150, height: 150)
            VStack(spacing: 2) {
                Text(tag).font(.subheadline.bold())
                Text(name).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var rawRingCell: some View {
        VStack(spacing: 10) {
            MultiRing(rings: [
                RingValue(id: 0, fillFraction: 0.9, fill: .linear(palette.trimester3)),
                RingValue(id: 1, fillFraction: 0.6, fill: .linear(palette.trimester2)),
                RingValue(id: 2, fillFraction: 0.4, fill: .linear(palette.trimester1)),
            ], lineWidth: 13, spacing: 4, style: style)
            .frame(width: 150, height: 150)
            VStack(spacing: 2) {
                Text("—").font(.subheadline.bold())
                Text("MultiRing (raw)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func labeled<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func radial<V: View>(_ title: String, @ViewBuilder _ content: () -> V) -> some View {
        VStack(spacing: 10) {
            content()
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
