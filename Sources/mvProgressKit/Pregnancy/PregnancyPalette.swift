import SwiftUI

/// Gender-driven color palette for pregnancy progress — the single source of
/// color truth. Trimester ramps mirror Clingy's `ProgressBarTheme`; the
/// `homeStretch` ramps are new: a deepening sweep *within* the gender hue for
/// weeks 37→40 (all third trimester, so trimester stops would read wrong).
public struct PregnancyPalette: Equatable, Sendable {
    /// Gradient stops (start, end) per trimester.
    public let trimester1: [Color]
    public let trimester2: [Color]
    public let trimester3: [Color]
    /// Three deepening gradient pairs for weeks 37–38, 38–39, 39–40.
    public let homeStretch: [[Color]]

    public func trimesterGradient(_ n: Int) -> [Color] {
        switch n {
        case 1: return trimester1
        case 2: return trimester2
        default: return trimester3
        }
    }

    public func trimesterLead(_ n: Int) -> Color {
        trimesterGradient(n).first ?? .accentColor
    }

    public static func forGender(_ gender: Gender) -> PregnancyPalette {
        switch gender {
        case .girl:    return .girl
        case .boy:     return .boy
        case .unknown: return .default
        }
    }

    // MARK: Named palettes

    /// Original app palette — pink → blue → green. Unknown/unset gender.
    public static let `default` = PregnancyPalette(
        trimester1: [Color(hex: "E91E63"), Color(hex: "F06292")],
        trimester2: [Color(hex: "2196F3"), Color(hex: "64B5F6")],
        trimester3: [Color(hex: "4CAF50"), Color(hex: "81C784")],
        homeStretch: [
            [Color(hex: "66BB6A"), Color(hex: "4CAF50")],
            [Color(hex: "4CAF50"), Color(hex: "43A047")],
            [Color(hex: "43A047"), Color(hex: "2E7D32")]
        ]
    )

    /// "Sunrise to rose" — peach → coral → pink, deepening in the home stretch.
    public static let girl = PregnancyPalette(
        trimester1: [Color(hex: "FFAB91"), Color(hex: "FF8A65")],
        trimester2: [Color(hex: "FF7E8C"), Color(hex: "FF5C7E")],
        trimester3: [Color(hex: "EC407A"), Color(hex: "E91E63")],
        homeStretch: [
            [Color(hex: "EC407A"), Color(hex: "E91E63")],
            [Color(hex: "E91E63"), Color(hex: "D81B60")],
            [Color(hex: "D81B60"), Color(hex: "AD1457")]
        ]
    )

    /// "Sky to royal" — sky → mid blue → royal, deepening to navy at the line.
    public static let boy = PregnancyPalette(
        trimester1: [Color(hex: "B3E5FC"), Color(hex: "81D4FA")],
        trimester2: [Color(hex: "4FC3F7"), Color(hex: "29B6F6")],
        trimester3: [Color(hex: "1976D2"), Color(hex: "1565C0")],
        homeStretch: [
            [Color(hex: "1E88E5"), Color(hex: "1976D2")],
            [Color(hex: "1976D2"), Color(hex: "1565C0")],
            [Color(hex: "1565C0"), Color(hex: "0D47A1")]
        ]
    )
}
