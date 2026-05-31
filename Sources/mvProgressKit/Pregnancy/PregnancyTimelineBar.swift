import SwiftUI

/// Data needed to render a pregnancy bar — produced by `make(for:)` from
/// primitive input, then handed to the generic `SegmentedBar`. This is the
/// thin domain layer: it knows trimesters, weeks, and overtime; the renderer
/// does not.
public struct PregnancyBarData: Sendable {
    public var segments: [ProgressSegment]
    public var markers: [ProgressMarker]
    public var fillFraction: Double
    public var overtime: OvertimeConfig?
    public var valueText: AttributedString

    /// Home-stretch geometry constants.
    static let dueAnchor = 0.78          // "Due" sits at 78% of the drawn span
    static let homeStretchWindowDays = 21.0   // weeks 37→40
    static let maxOvertimeDays = 14.0    // cap at 42 weeks

    public static func make(for input: PregnancyBarInput) -> PregnancyBarData {
        let palette = PregnancyPalette.forGender(input.gender)
        return input.isLaborReady ? homeStretch(input, palette)
                                  : fullPregnancy(input, palette)
    }

    // MARK: Full-pregnancy preset (weeks 0–36)

    private static func fullPregnancy(_ input: PregnancyBarInput,
                                      _ palette: PregnancyPalette) -> PregnancyBarData {
        let segments = [
            ProgressSegment(id: 0, fraction: 0.35, fill: .linear(palette.trimester1)),
            ProgressSegment(id: 1, fraction: 0.35, fill: .linear(palette.trimester2)),
            ProgressSegment(id: 2, fraction: 0.30, fill: .linear(palette.trimester3)),
        ]
        let markers = [(12, 0.30), (20, 0.50), (28, 0.70), (36, 0.90)]
            .enumerated()
            .map { ProgressMarker(id: $0.offset, position: $0.element.1, label: "\($0.element.0)") }
        let fill = min(max(input.progressPercent / 100.0, 0), 1)
        return PregnancyBarData(segments: segments, markers: markers,
                                fillFraction: fill, overtime: nil,
                                valueText: daysValue(input.daysUntilDue))
    }

    // MARK: Home-stretch preset (weeks 37+)

    private static func homeStretch(_ input: PregnancyBarInput,
                                    _ palette: PregnancyPalette) -> PregnancyBarData {
        let segFrac = dueAnchor / 3.0
        let segments = (0..<3).map {
            ProgressSegment(id: $0, fraction: segFrac, fill: .linear(palette.homeStretch[$0]))
        }
        let markers = [(37, 0.0), (38, segFrac), (39, segFrac * 2), (40, dueAnchor)]
            .enumerated()
            .map { ProgressMarker(id: $0.offset, position: $0.element.1, label: "\($0.element.0)") }

        // Progress toward the due date within the 21-day window.
        let daysInto = homeStretchWindowDays - Double(input.daysUntilDue)
        let toDue = min(max(daysInto / homeStretchWindowDays, 0), 1)
        var fill = toDue * dueAnchor
        var overtime = OvertimeConfig(dueAnchor: dueAnchor)

        if input.isOverdue {
            let daysOver = Double(-input.daysUntilDue)
            let otProgress = min(max(daysOver / maxOvertimeDays, 0), 1)
            fill = dueAnchor + otProgress * (1 - dueAnchor)
            let activeWeeks = min(Int(ceil(daysOver / 7.0)), 2)
            overtime = OvertimeConfig(dueAnchor: dueAnchor,
                                      activeWeeks: activeWeeks,
                                      tailFill: otProgress)
        }

        return PregnancyBarData(segments: segments, markers: markers,
                                fillFraction: fill, overtime: overtime,
                                valueText: daysValue(input.daysUntilDue))
    }

    // MARK: Value label

    static func daysValue(_ days: Int) -> AttributedString {
        if days > 0 {
            var count = AttributedString("\(days)")
            count.font = .system(size: 14, weight: .bold)
            var unit = AttributedString(" days to go")
            unit.font = .system(size: 12, weight: .medium)
            return count + unit
        } else if days == 0 {
            var s = AttributedString("Due today")
            s.font = .system(size: 13, weight: .bold)
            return s
        } else {
            var count = AttributedString("+\(-days)")
            count.font = .system(size: 14, weight: .bold)
            var unit = AttributedString(" days")
            unit.font = .system(size: 12, weight: .medium)
            return count + unit
        }
    }
}

/// The ergonomic call site: hand it pregnancy input, it picks the right preset
/// (full-pregnancy vs home-stretch) off the week signal and renders. This is
/// the live consumer Clingy's Prep tab will use.
public struct PregnancyTimelineBar: View {
    public var input: PregnancyBarInput
    public var size: BarSize
    public var overlays: ProgressOverlays
    public var style: ProgressStyle

    public init(input: PregnancyBarInput,
                size: BarSize = .standard,
                overlays: ProgressOverlays = .full,
                style: ProgressStyle = .glass) {
        self.input = input
        self.size = size
        self.overlays = overlays
        self.style = style
    }

    public var body: some View {
        let data = PregnancyBarData.make(for: input)
        SegmentedBar(segments: data.segments,
                     markers: data.markers,
                     fillFraction: data.fillFraction,
                     overtime: data.overtime,
                     valueText: data.valueText,
                     size: size,
                     style: style,
                     overlays: overlays)
    }
}
