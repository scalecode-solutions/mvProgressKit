import SwiftUI

/// What a ring's center readout shows. A small mapper off `PregnancyBarInput` —
/// the same flag rides every ring family (`PregnancyRings`, the dial rings, …),
/// so the host picks "weeks" vs "days to go" vs a custom string per use-case.
public enum RingCenter: Sendable, Equatable {
    case none
    case weeks
    case daysToDue
    case percent
    case custom(value: String, caption: String)

    /// The (big value, small caption) pair for an input — or nil to draw nothing.
    public func content(for input: PregnancyBarInput) -> (value: String, caption: String)? {
        switch self {
        case .none:
            return nil
        case .weeks:
            return ("\(input.completedWeeks)", "weeks")
        case .daysToDue:
            let d = input.daysUntilDue
            if d > 0 { return ("\(d)", d == 1 ? "day to go" : "days to go") }
            if d == 0 { return ("Due", "today") }
            return ("\(-d)", -d == 1 ? "day over" : "days over")
        case .percent:
            return ("\(Int(input.progressPercent.rounded()))", "% complete")
        case .custom(let value, let caption):
            return (value, caption)
        }
    }
}

/// The adaptive center label — big value over a small caption, scaled to the
/// ring's clear inner hole so it never collides with the surrounding bands.
struct RingCenterLabel: View {
    let value: String
    let caption: String
    let diameter: CGFloat
    var valueColor: Color = .primary

    var body: some View {
        VStack(spacing: 0) {
            Text(value)
                .font(.system(size: diameter * 0.40, weight: .bold))
                .foregroundStyle(valueColor)
                .monospacedDigit()
            if !caption.isEmpty {
                Text(caption)
                    .font(.system(size: diameter * 0.15, weight: .medium))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .frame(width: diameter)
    }
}
