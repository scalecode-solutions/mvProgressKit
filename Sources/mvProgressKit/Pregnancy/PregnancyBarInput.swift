import Foundation

/// The pregnancy lifecycle phases. Boundaries match Clingy's dashboard preset
/// ladder (1st 1–13 · 2nd 14–27 · 3rd 28–36 · Labor Ready 37–42) so the bar's
/// mode switch rides the *same* week signal the dashboard already keys off.
public enum PregnancyPhase: Sendable, Equatable {
    case first, second, third, laborReady

    /// First week of the Labor Ready / home-stretch phase. Single source of
    /// truth for the bar's `.fullPregnancy` → `.homeStretch` switch.
    public static let laborReadyStartWeek = 37

    public static func phase(forCompletedWeeks weeks: Int) -> PregnancyPhase {
        switch weeks {
        case ..<14:                    return .first
        case 14..<28:                  return .second
        case 28..<laborReadyStartWeek: return .third
        default:                       return .laborReady
        }
    }
}

/// Primitive inputs the bar needs — no Clingy types. Clingy builds this from
/// its `Pregnancy` at the call site.
public struct PregnancyBarInput: Equatable, Sendable {
    public var completedWeeks: Int
    public var currentWeek: Int
    public var dayOfWeek: Int          // 0...6 into the current week
    public var daysUntilDue: Int       // negative when overdue
    public var progressPercent: Double // 0...100 across the full ~280-day span
    public var gender: Gender

    public init(completedWeeks: Int,
                currentWeek: Int,
                dayOfWeek: Int,
                daysUntilDue: Int,
                progressPercent: Double,
                gender: Gender) {
        self.completedWeeks = completedWeeks
        self.currentWeek = currentWeek
        self.dayOfWeek = dayOfWeek
        self.daysUntilDue = daysUntilDue
        self.progressPercent = progressPercent
        self.gender = gender
    }

    public var phase: PregnancyPhase { .phase(forCompletedWeeks: completedWeeks) }
    public var isLaborReady: Bool { phase == .laborReady }
    public var isOverdue: Bool { daysUntilDue < 0 }
}
