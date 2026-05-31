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
    public var dayOfWeek: Int          // 0...6 into the current week
    public var daysUntilDue: Int       // negative when overdue
    public var progressPercent: Double // 0...100 across the full ~280-day span
    public var gender: Gender
    public var dueDate: Date?          // for "Due {date}" on the info card

    public init(completedWeeks: Int,
                dayOfWeek: Int,
                daysUntilDue: Int,
                progressPercent: Double,
                gender: Gender,
                dueDate: Date? = nil) {
        self.completedWeeks = completedWeeks
        self.dayOfWeek = dayOfWeek
        self.daysUntilDue = daysUntilDue
        self.progressPercent = progressPercent
        self.gender = gender
        self.dueDate = dueDate
    }

    public var phase: PregnancyPhase { .phase(forCompletedWeeks: completedWeeks) }
    public var isLaborReady: Bool { phase == .laborReady }
    public var isOverdue: Bool { daysUntilDue < 0 }

    /// Medical trimester number (1/2/3) — labor-ready weeks are still 3rd.
    public var trimesterNumber: Int {
        switch completedWeeks {
        case ..<14:   return 1
        case 14..<28: return 2
        default:      return 3
        }
    }

    public var trimesterName: String {
        switch trimesterNumber {
        case 1:  return "First Trimester"
        case 2:  return "Second Trimester"
        default: return "Third Trimester"
        }
    }

    /// Compact ordinal form for chips ("1st/2nd/3rd Trimester").
    public var trimesterNameShort: String {
        switch trimesterNumber {
        case 1:  return "1st Trimester"
        case 2:  return "2nd Trimester"
        default: return "3rd Trimester"
        }
    }

    /// Ordinal only ("1st/2nd/3rd") — smallest chip form.
    public var trimesterOrdinal: String {
        switch trimesterNumber {
        case 1:  return "1st"
        case 2:  return "2nd"
        default: return "3rd"
        }
    }

    /// "37 weeks" / "37 weeks, 1 day".
    public var weekDayText: String {
        dayOfWeek > 0
            ? "\(completedWeeks) weeks, \(dayOfWeek) day\(dayOfWeek == 1 ? "" : "s")"
            : "\(completedWeeks) weeks"
    }

    /// "Week 37" / "Week 37, Day 1".
    public var weekLabelText: String {
        dayOfWeek > 0 ? "Week \(completedWeeks), Day \(dayOfWeek)" : "Week \(completedWeeks)"
    }

    /// Continuous week position (e.g. 37.57), for alignment math.
    public var weeksContinuous: Double { Double(completedWeeks) + Double(dayOfWeek) / 7.0 }

    /// Plain countdown phrase — shared by the info card and accessibility.
    public var daysSummary: String {
        if daysUntilDue > 0 { return "\(daysUntilDue) days to go" }
        if daysUntilDue == 0 { return "Due today" }
        return "\(-daysUntilDue) days overdue"
    }
}
