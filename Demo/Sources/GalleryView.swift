import SwiftUI
import mvProgressKit

/// Interactive harness — one week slider (0→44) drives the whole pregnancy
/// lifecycle including the week-37 home-stretch switch and overtime past 40;
/// the gender picker re-themes everything live. Every component renders below.
struct GalleryView: View {
    @State private var week: Double = 24.5
    @State private var gender: Gender = .girl
    @State private var coloring: RingColoring = .byRadius

    // MARK: Derived pregnancy input

    private var input: PregnancyBarInput {
        PregnancyBarInput(
            completedWeeks: Int(week),
            currentWeek: Int(week) + 1,
            dayOfWeek: Int((week - Double(Int(week))) * 7),
            daysUntilDue: Int((40.0 - week) * 7),
            progressPercent: min(week / 40.0 * 100.0, 100),
            gender: gender
        )
    }

    private var palette: PregnancyPalette { .forGender(gender) }
    private var deepFill: ProgressFill { .linear(palette.trimester3) }
    private var taskFill: Double { min(week / 44.0, 1) }
    private var stepsDone: Int { Int((week / 44.0) * 5) }

    private var phaseLabel: String {
        switch input.phase {
        case .first: return "1st Trimester"
        case .second: return "2nd Trimester"
        case .third: return "3rd Trimester"
        case .laborReady: return input.isOverdue ? "Labor Ready · OVERDUE" : "Labor Ready (home stretch)"
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                controls

                // Rings up top, large, 2 per row.
                ringsGrid

                section("PregnancyTimelineBar — standard (full)") {
                    PregnancyTimelineBar(input: input, size: .standard, overlays: .full)
                }
                section("PregnancyTimelineBar — compact (full)") {
                    PregnancyTimelineBar(input: input, size: .compact, overlays: .full)
                }
                section("PregnancyTimelineBar — lean (Prep landing)") {
                    PregnancyTimelineBar(input: input, size: .standard, overlays: .lean)
                }
                section("TrackBar — task completion") {
                    TrackBar(fillFraction: taskFill, fill: deepFill, size: .compact)
                }
                section("StepIndicator — checklist sections") {
                    StepIndicator(steps: stepMarkers, fill: deepFill).frame(height: 40)
                }

                HStack(spacing: 24) {
                    labeledRadial("ProgressRing") {
                        ProgressRing(fillFraction: taskFill, fill: deepFill, lineWidth: 12) {
                            Text("\(Int(taskFill * 100))%").font(.headline)
                        }
                    }
                    labeledRadial("Gauge") {
                        ProgressGauge(fillFraction: input.progressPercent / 100, fill: deepFill) {
                            Text("\(Int(week))w").font(.headline)
                        }
                    }
                }
                .padding(.top, 4)
            }
            .padding(20)
        }
        .background(Color.black.opacity(0.92))
        .preferredColorScheme(.dark)
    }

    // MARK: Controls

    private var controls: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("mvProgressKit")
                .font(.largeTitle.bold())
            HStack {
                Text("Week \(Int(week))")
                    .font(.headline).monospacedDigit()
                Spacer()
                Text(phaseLabel)
                    .font(.subheadline)
                    .foregroundStyle(input.isLaborReady ? .pink : .secondary)
            }
            Slider(value: $week, in: 0...44)
            Picker("Gender", selection: $gender) {
                Text("Girl").tag(Gender.girl)
                Text("Boy").tag(Gender.boy)
                Text("Unknown").tag(Gender.unknown)
            }
            .pickerStyle(.segmented)
            Picker("Coloring", selection: $coloring) {
                Text("by radius").tag(RingColoring.byRadius)
                Text("by metric").tag(RingColoring.byMetric)
            }
            .pickerStyle(.segmented)
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: Rings grid (2 per row)

    private var ringsGrid: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("PregnancyRings — arrangements + raw MultiRing")
                .font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            HStack(spacing: 16) {
                ringCell("A", "containment") {
                    PregnancyRings(input: input, arrangement: .containment, coloring: coloring, lineWidth: 13, spacing: 4)
                }
                ringCell("B", "recency") {
                    PregnancyRings(input: input, arrangement: .recency, coloring: coloring, lineWidth: 13, spacing: 4)
                }
            }
            HStack(spacing: 16) {
                ringCell("C", "timeline-core") {
                    PregnancyRings(input: input, arrangement: .timelineCore, coloring: coloring, lineWidth: 13, spacing: 4)
                }
                ringCell("—", "MultiRing (raw)") {
                    MultiRing(rings: [
                        RingValue(id: 0, fillFraction: 0.9, fill: .linear(palette.trimester3)),
                        RingValue(id: 1, fillFraction: 0.6, fill: .linear(palette.trimester2)),
                        RingValue(id: 2, fillFraction: 0.4, fill: .linear(palette.trimester1)),
                    ], lineWidth: 13, spacing: 4)
                }
            }
        }
    }

    private func ringCell<V: View>(_ tag: String, _ name: String,
                                   @ViewBuilder _ content: () -> V) -> some View {
        VStack(spacing: 10) {
            content().frame(width: 150, height: 150)
            VStack(spacing: 2) {
                Text(tag).font(.subheadline.bold())
                Text(name).font(.caption).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Other components

    private var stepMarkers: [ProgressMarker] {
        (0..<5).map { i in
            let state: NodeState = i < stepsDone ? .done : (i == stepsDone ? .active : .todo)
            return ProgressMarker(id: i, position: Double(i) / 4.0, label: "\(i + 1)", state: state)
        }
    }

    // MARK: Layout helpers

    private func section<Content: View>(_ title: String,
                                        @ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.secondary)
            content()
        }
    }

    private func labeledRadial<Content: View>(_ title: String,
                                              @ViewBuilder _ content: () -> Content) -> some View {
        VStack(spacing: 8) {
            content().frame(width: 90, height: 90)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    GalleryView()
}
