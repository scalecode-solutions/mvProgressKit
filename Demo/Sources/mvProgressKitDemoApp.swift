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
    case timeline, rings, segmented, trackbar, steps, ring, gauge, multiring

    var id: String { rawValue }

    var title: String {
        switch self {
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
        case .timeline, .rings:               return "Pregnancy"
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
        var chrome: Bool
    }

    static func initial() -> State {
        let d = UserDefaults.standard
        let unfilled: UnfilledStyle = d.string(forKey: "unfilled") == "neutral"
            ? .neutral : .shade(0.85)
        let overtime: OvertimeStyle = d.string(forKey: "overtime") == "reserved"
            ? .reserved : .tear
        return State(
            screen: d.string(forKey: "screen").flatMap(DemoScreen.init(rawValue:)),
            week: d.object(forKey: "week") != nil ? d.double(forKey: "week") : 24.5,
            gender: d.string(forKey: "gender").flatMap(Gender.init(rawValue:)) ?? .girl,
            coloring: d.string(forKey: "coloring").flatMap(RingColoring.init(rawValue:)) ?? .byRadius,
            unfilled: unfilled,
            overtime: overtime,
            chrome: d.object(forKey: "chrome") != nil ? d.bool(forKey: "chrome") : true
        )
    }
}
