import SwiftUI
import mvProgressKit

@main
struct mvProgressKitDemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// The component screens. Raw values double as deep-link ids (`-screen rings`).
enum DemoScreen: String, CaseIterable, Identifiable, Hashable {
    case infoCard, timeline, rings, segmented, trackbar, steps, ring, gauge, multiring

    var id: String { rawValue }

    var title: String {
        switch self {
        case .infoCard:  return "Info Card"
        case .timeline:  return "Timeline Bar"
        case .rings:     return "Pregnancy Rings"
        case .segmented: return "Segmented Bar (raw)"
        case .trackbar:  return "Track Bar"
        case .steps:     return "Step Indicator"
        case .ring:      return "Progress Ring"
        case .gauge:     return "Gauge"
        case .multiring: return "Multi Ring"
        }
    }

    var family: String {
        switch self {
        case .infoCard, .timeline, .rings:    return "Pregnancy"
        case .segmented, .trackbar, .steps:   return "Linear"
        case .ring, .gauge, .multiring:       return "Radial"
        }
    }

    static let families = ["Pregnancy", "Linear", "Radial"]
}

/// Initial state seeded from launch args (parsed via the NSArgumentDomain, so
/// `-screen rings -week 41 -gender boy -coloring byMetric -chrome 0` just works).
enum DemoLaunch {
    struct State {
        var screen: DemoScreen?
        var week: Double
        var gender: Gender
        var coloring: RingColoring
        var unfilled: UnfilledStyle
        var overtime: OvertimeStyle
        var glass: Bool
        var indicator: PositionIndicator
        var label: TimelineLabel
        var animate: Bool
        var scheme: ColorScheme?
        var daysText: String?
        var chrome: Bool
    }

    static func initial() -> State {
        let d = UserDefaults.standard
        let animate = d.bool(forKey: "animate")
        let scheme: ColorScheme?
        switch d.string(forKey: "scheme") {
        case "light":  scheme = .light
        case "system": scheme = nil
        default:       scheme = .dark
        }
        let showBase = d.object(forKey: "base") != nil ? d.bool(forKey: "base") : false
        let unfilled: UnfilledStyle = d.string(forKey: "unfilled") == "neutral"
            ? .neutral : .shade(lighten: 0.85, opacity: 0.3, base: showBase)
        let overtime: OvertimeStyle = d.string(forKey: "overtime") == "reserved"
            ? .reserved : .tear
        let indicator: PositionIndicator
        switch d.string(forKey: "indicator") {
        case "heart":   indicator = .symbol("heart.fill")
        case "diamond": indicator = .symbol("diamond.fill")
        case "star":    indicator = .symbol("star.fill")
        case "none":    indicator = .none
        default:        indicator = .dot
        }
        let label: TimelineLabel
        switch d.string(forKey: "label") {
        case "week": label = .week
        case "both": label = .both
        case "none": label = .none
        default:     label = .days
        }
        return State(
            screen: d.string(forKey: "screen").flatMap(DemoScreen.init(rawValue:)),
            week: d.object(forKey: "week") != nil ? d.double(forKey: "week") : (animate ? 39 : 24.5),
            gender: d.string(forKey: "gender").flatMap(Gender.init(rawValue:)) ?? .girl,
            coloring: d.string(forKey: "coloring").flatMap(RingColoring.init(rawValue:)) ?? .byRadius,
            unfilled: unfilled,
            overtime: overtime,
            glass: d.object(forKey: "glass") != nil ? d.bool(forKey: "glass") : true,
            indicator: indicator,
            label: label,
            animate: animate,
            scheme: scheme,
            daysText: d.string(forKey: "daystext"),
            chrome: d.object(forKey: "chrome") != nil ? d.bool(forKey: "chrome") : true
        )
    }
}
