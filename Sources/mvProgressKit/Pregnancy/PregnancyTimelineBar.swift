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
    static let homeStretchWindowDays = 21.0   // weeks 37→40
    static let maxOvertimeDays = 14.0    // cap at 42 weeks

    public static func make(for input: PregnancyBarInput,
                            overtimeStyle: OvertimeStyle = .tear) -> PregnancyBarData {
        let palette = PregnancyPalette.forGender(input.gender)
        return input.isLaborReady ? homeStretch(input, palette, overtimeStyle)
                                  : fullPregnancy(input, palette)
    }

    // MARK: Full-pregnancy preset (weeks 0–36)

    private static func fullPregnancy(_ input: PregnancyBarInput,
                                      _ palette: PregnancyPalette) -> PregnancyBarData {
        // One fill, colored by the *current* trimester — the hue shifts as you
        // cross into each trimester (cleaner + glass-friendly vs tricolor segments).
        let tri: Int
        switch input.phase {
        case .first:  tri = 1
        case .second: tri = 2
        default:      tri = 3
        }
        let segments = [
            ProgressSegment(id: 0, fraction: 1.0, fill: .linear(palette.trimesterGradient(tri)))
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
                                    _ palette: PregnancyPalette,
                                    _ overtimeStyle: OvertimeStyle) -> PregnancyBarData {
        // On-time span = weeks 37→40 across the full pill (overtime tears off).
        // Light tint behind the deep ramp keeps the unfilled track clean.
        let trackTint = palette.trimester1.first
        // One fill spanning a subtle light→deep sweep of the home-stretch hue.
        let hsRamp = [palette.homeStretch.first?.first, palette.homeStretch.last?.last].compactMap { $0 }
        let hsFill: ProgressFill = hsRamp.count == 2 ? .linear(hsRamp) : .linear(palette.trimester3)
        let segments = [
            ProgressSegment(id: 0, fraction: 1.0, fill: hsFill, tint: trackTint)
        ]
        let markers = [(37, 0.0), (38, 1.0 / 3.0), (39, 2.0 / 3.0), (40, 1.0)]
            .enumerated()
            .map { ProgressMarker(id: $0.offset, position: $0.element.1, label: "\($0.element.0)") }

        // Progress toward the due date within the 21-day window (0→1 fills the pill).
        let daysInto = homeStretchWindowDays - Double(input.daysUntilDue)
        let toDue = min(max(daysInto / homeStretchWindowDays, 0), 1)
        var fill = toDue
        var overtime = OvertimeConfig(fraction: 0, activeWeeks: 0, style: overtimeStyle)

        if input.isOverdue {
            let daysOver = Double(-input.daysUntilDue)
            let otFraction = min(max(daysOver / maxOvertimeDays, 0), 1)
            let activeWeeks = min(Int(ceil(daysOver / 7.0)), 2)
            fill = 1.0  // on-time pill is complete; overtime carries the rest
            overtime = OvertimeConfig(fraction: otFraction,
                                      activeWeeks: activeWeeks,
                                      style: overtimeStyle)
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
/// What the value caption shows.
public enum TimelineLabel: Sendable, Equatable {
    case none, days, week, both
}

public struct PregnancyTimelineBar: View {
    public var input: PregnancyBarInput
    public var size: BarSize
    public var overlays: ProgressOverlays
    public var style: ProgressStyle
    public var overtimeStyle: OvertimeStyle
    public var label: TimelineLabel

    public init(input: PregnancyBarInput,
                size: BarSize = .standard,
                overlays: ProgressOverlays = .full,
                style: ProgressStyle = .glass,
                overtimeStyle: OvertimeStyle = .tear,
                label: TimelineLabel = .days) {
        self.input = input
        self.size = size
        self.overlays = overlays
        self.style = style
        self.overtimeStyle = overtimeStyle
        self.label = label
    }

    public var body: some View {
        let data = PregnancyBarData.make(for: input, overtimeStyle: overtimeStyle)
        let days = data.valueText
        let week = Self.weekText(input.completedWeeks)
        let leading: AttributedString?
        let trailing: AttributedString?
        switch label {
        case .none: (leading, trailing) = (nil, nil)
        case .days: (leading, trailing) = (days, nil)
        case .week: (leading, trailing) = (week, nil)
        case .both: (leading, trailing) = (days, week)
        }

        return SegmentedBar(segments: data.segments,
                            markers: data.markers,
                            fillFraction: data.fillFraction,
                            overtime: data.overtime,
                            valueText: leading,
                            trailingText: trailing,
                            size: size,
                            style: style,
                            overlays: overlays)
    }

    static func weekText(_ week: Int) -> AttributedString {
        var s = AttributedString("Week \(week)")
        s.font = .system(size: 14, weight: .semibold)
        return s
    }
}
