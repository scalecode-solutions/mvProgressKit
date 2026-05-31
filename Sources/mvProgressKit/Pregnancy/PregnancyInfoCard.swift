import SwiftUI

/// Prebuilt pregnancy info card — title + due/countdown + trimester chip + the
/// timeline bar — composed from pieces the kit already owns. Chrome-less and
/// navigation-less on purpose: the host app wraps it with its own card surface
/// and tap behavior. Strings are kit-computed but overridable so the host can
/// pass its canonical values.
public struct PregnancyInfoCard: View {
    public enum Style: Sendable, Equatable { case standard, compact }

    public var input: PregnancyBarInput
    public var style: Style
    public var barStyle: ProgressStyle
    public var overtimeStyle: OvertimeStyle
    public var indicator: PositionIndicator
    public var showMarkers: Bool
    public var weekText: String?
    public var trimesterText: String?
    public var dueText: String?

    public init(input: PregnancyBarInput,
                style: Style = .standard,
                barStyle: ProgressStyle = .glass,
                overtimeStyle: OvertimeStyle = .tear,
                indicator: PositionIndicator = .dot,
                showMarkers: Bool = true,
                weekText: String? = nil,
                trimesterText: String? = nil,
                dueText: String? = nil) {
        self.input = input
        self.style = style
        self.barStyle = barStyle
        self.overtimeStyle = overtimeStyle
        self.indicator = indicator
        self.showMarkers = showMarkers
        self.weekText = weekText
        self.trimesterText = trimesterText
        self.dueText = dueText
    }

    private var palette: PregnancyPalette { .forGender(input.gender) }
    private var chipColor: Color { palette.trimesterLead(input.trimesterNumber) }
    private var trimester: String { trimesterText ?? input.trimesterName }

    private func dueString(short: Bool) -> String {
        if let dueText { return dueText }
        guard let due = input.dueDate else { return "—" }
        let f = DateFormatter()
        f.dateFormat = short ? "MMM d" : "MMMM d, yyyy"
        return f.string(from: due)
    }

    private var daysString: String {
        let d = input.daysUntilDue
        if d > 0 { return "\(d) days to go" }
        if d == 0 { return "Due today" }
        return "\(-d) days overdue"
    }

    public var body: some View {
        switch style {
        case .standard: standard
        case .compact:  compact
        }
    }

    // MARK: Standard

    private var standard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("You are \(weekText ?? input.weekDayText) along!")
                    .font(.system(size: 22, weight: .bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Spacer(minLength: 8)
                chip
            }
            HStack(spacing: 6) {
                Image(systemName: "calendar")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.secondary)
                Text("Due \(dueString(short: false)) · \(daysString)")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            PregnancyTimelineBar(
                input: input,
                size: .standard,
                overlays: ProgressOverlays(caption: .none, indicator: indicator, glow: true,
                                           markerTicks: showMarkers, markerLabels: showMarkers,
                                           dividers: false),
                style: barStyle,
                overtimeStyle: overtimeStyle,
                label: .none
            )
        }
    }

    // MARK: Compact

    private var compact: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(weekText ?? input.weekLabelText)
                    .font(.system(size: 15, weight: .bold))
                Spacer()
                chip
                Spacer()
                Text("Due \(dueString(short: true))")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.secondary)
            }
            PregnancyTimelineBar(
                input: input,
                size: .compact,
                overlays: ProgressOverlays(caption: .inside, indicator: indicator, glow: true,
                                           markerTicks: false, markerLabels: false, dividers: false),
                style: barStyle,
                overtimeStyle: overtimeStyle,
                label: .days
            )
        }
    }

    private var chip: some View {
        Text(trimester)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(chipColor))
    }
}
