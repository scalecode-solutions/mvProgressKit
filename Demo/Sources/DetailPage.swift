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

    private var palette: PregnancyPalette { .forGender(input.gender) }
    private var deepFill: ProgressFill { .linear(palette.trimester3) }
    private var demoFraction: Double { min(max(input.progressPercent / 100.0, 0), 1) }
    private var stepsDone: Int { Int(demoFraction * 5) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                switch screen {
                case .timeline:  timeline
                case .rings:     rings
                case .segmented: segmented
                case .trackbar:  trackbar
                case .steps:     steps
                case .ring:      ring
                case .gauge:     gauge
                case .multiring: multiring
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.black.opacity(0.92))
    }

    // MARK: Pages

    private var timeline: some View {
        VStack(alignment: .leading, spacing: 24) {
            labeled("standard · full") { PregnancyTimelineBar(input: input, size: .standard, overlays: .full, style: style, overtimeStyle: overtimeStyle) }
            labeled("compact · full") { PregnancyTimelineBar(input: input, size: .compact, overlays: .full, style: style, overtimeStyle: overtimeStyle) }
            labeled("lean · Prep landing") { PregnancyTimelineBar(input: input, size: .standard, overlays: .lean, style: style, overtimeStyle: overtimeStyle) }
            labeled("bare") { PregnancyTimelineBar(input: input, size: .standard, overlays: .bare, style: style, overtimeStyle: overtimeStyle) }
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
                overlays: ProgressOverlays(valueLabel: false, positionDot: true,
                                           glow: true, markers: true, dividers: true)
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
                ProgressRing(fillFraction: demoFraction, fill: deepFill, lineWidth: 16, style: style) {
                    Text("\(Int(demoFraction * 100))%").font(.title2.bold())
                }
            }
            radial("bare") {
                ProgressRing(fillFraction: demoFraction, fill: deepFill, lineWidth: 16, style: style)
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

    private var multiring: some View {
        radial("raw MultiRing") {
            MultiRing(rings: [
                RingValue(id: 0, fillFraction: 0.9, fill: .linear(palette.trimester3)),
                RingValue(id: 1, fillFraction: 0.6, fill: .linear(palette.trimester2)),
                RingValue(id: 2, fillFraction: 0.4, fill: .linear(palette.trimester1)),
            ], lineWidth: 16, style: style)
        }
        .frame(height: 240)
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
                           style: style, lineWidth: 13, spacing: 4)
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
