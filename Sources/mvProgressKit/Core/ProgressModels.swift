import SwiftUI

// MARK: - Fill

/// How a filled region (bar segment, ring stroke, gauge arc) is painted.
/// The renderer maps this to a concrete `ShapeStyle`, choosing gradient
/// direction by context (leading→trailing for bars, along-arc for rings).
public enum ProgressFill: Equatable, Sendable {
    case solid(Color)
    /// Gradient stops, drawn start→end along the track.
    case linear([Color])
    /// Angular gradient stops, for radial tracks.
    case angular([Color])

    /// The lead (start) color — used for faint segment tints, dot glow, etc.
    public var leadColor: Color {
        switch self {
        case .solid(let c):       return c
        case .linear(let cs):     return cs.first ?? .clear
        case .angular(let cs):    return cs.first ?? .clear
        }
    }

    /// Resolve to a type-erased `ShapeStyle` for a linear track.
    public func linearStyle(start: UnitPoint = .leading,
                            end: UnitPoint = .trailing) -> AnyShapeStyle {
        switch self {
        case .solid(let c):
            return AnyShapeStyle(c)
        case .linear(let cs):
            return AnyShapeStyle(LinearGradient(colors: cs, startPoint: start, endPoint: end))
        case .angular(let cs):
            return AnyShapeStyle(LinearGradient(colors: cs, startPoint: start, endPoint: end))
        }
    }

    /// Resolve to a type-erased `ShapeStyle` for a radial track.
    public func radialStyle(center: UnitPoint = .center) -> AnyShapeStyle {
        switch self {
        case .solid(let c):
            return AnyShapeStyle(c)
        case .linear(let cs):
            return AnyShapeStyle(AngularGradient(colors: cs, center: center))
        case .angular(let cs):
            return AnyShapeStyle(AngularGradient(colors: cs, center: center))
        }
    }

    /// A faint, lightened "ghost" of this fill for unfilled tracks — every stop
    /// blended toward white by `lighten`, then dropped to `opacity`. Keeps the
    /// gradient (so the track reads as the same material as the fill, not a
    /// flat slab) but airy and see-through.
    public func track(lighten: Double, opacity: Double) -> ProgressFill {
        func ghost(_ c: Color) -> Color { c.lightened(by: lighten).opacity(opacity) }
        switch self {
        case .solid(let c):    return .solid(ghost(c))
        case .linear(let cs):  return .linear(cs.map(ghost))
        case .angular(let cs): return .angular(cs.map(ghost))
        }
    }
}

// MARK: - Segment

/// A proportional slice of a linear track (a trimester, a week, a category).
public struct ProgressSegment: Identifiable, Equatable, Sendable {
    public let id: Int
    /// Width as a fraction of the whole drawn span (segments need not sum to 1;
    /// any remainder is reserved space — e.g. a dormant overtime tail).
    public var fraction: Double
    /// Paint for the filled portion of this segment.
    public var fill: ProgressFill
    /// Faint background tint behind the glass track for this segment.
    /// Defaults to the fill's lead color at low opacity when `nil`.
    public var tint: Color?
    public var label: String?

    public init(id: Int,
                fraction: Double,
                fill: ProgressFill,
                tint: Color? = nil,
                label: String? = nil) {
        self.id = id
        self.fraction = fraction
        self.fill = fill
        self.tint = tint
        self.label = label
    }
}

// MARK: - Marker / Node

/// State of a step node. `nil` state on a marker means "plain tick", not a node.
public enum NodeState: Equatable, Sendable {
    case todo, active, done
}

/// A point of interest along a track: a week tick, a milestone, or a step node.
/// `state == nil` → a plain labeled tick; `state != nil` → a step-indicator node.
public struct ProgressMarker: Identifiable, Equatable, Sendable {
    public let id: Int
    /// Position along the track, 0...1.
    public var position: Double
    public var label: String?
    public var state: NodeState?

    public init(id: Int,
                position: Double,
                label: String? = nil,
                state: NodeState? = nil) {
        self.id = id
        self.position = position
        self.label = label
        self.state = state
    }
}

// MARK: - Overtime

/// How overtime is drawn once the value passes the on-time span.
public enum OvertimeStyle: Sendable, Equatable {
    /// The on-time pill spans the full width until due, then **tears**: the
    /// main pill compresses and squares its right edge, and a separate
    /// overtime pill buds off past a gap. The reflow is the "you crossed the
    /// line" moment.
    case tear
    /// The overtime pill's slot is always reserved (faint when empty) and just
    /// fills in when overdue — no reflow.
    case reserved
}

/// Split-pill overtime: the on-time span and the overtime span render as two
/// separate capsules (rounded outer ends, flat inner ends) with a gap between.
public struct OvertimeConfig: Equatable, Sendable {
    /// Fill within the overtime window, 0...1.
    public var fraction: Double
    /// Weeks of overtime currently active (0 = on time).
    public var activeWeeks: Int
    public var style: OvertimeStyle
    /// Width fraction the on-time pill takes once the overtime pill is shown.
    public var mainWidth: Double
    /// Gap fraction between the two pills.
    public var gap: Double
    /// Maximum overtime weeks.
    public var maxWeeks: Int

    public init(fraction: Double = 0,
                activeWeeks: Int = 0,
                style: OvertimeStyle = .tear,
                mainWidth: Double = 0.72,
                gap: Double = 0.025,
                maxWeeks: Int = 2) {
        self.fraction = min(max(fraction, 0), 1)
        self.activeWeeks = min(activeWeeks, maxWeeks)
        self.style = style
        self.mainWidth = mainWidth
        self.gap = gap
        self.maxWeeks = maxWeeks
    }

    /// Is overtime currently happening?
    public var isActive: Bool { activeWeeks > 0 || fraction > 0 }
    /// Should the overtime pill be drawn at all? (always for `.reserved`.)
    public var isShown: Bool { style == .reserved || isActive }
    /// The on-time pill's width fraction given style/state (full until shown).
    public var resolvedMainWidth: Double { isShown ? mainWidth : 1.0 }
}

// MARK: - Overlays

/// The "you are here" marker that rides the fill edge.
public enum PositionIndicator: Sendable, Equatable {
    case none
    /// The default white circle.
    case dot
    /// Any SF Symbol, e.g. `"heart.fill"`, `"diamond.fill"`, `"star.fill"`.
    case symbol(String)
}

/// Toggles for the chrome drawn on top of a track. Presets cover the common
/// "everything", "lean", and "bare" cases; tweak individual flags as needed.
public struct ProgressOverlays: Equatable, Sendable {
    public var valueLabel: Bool
    public var indicator: PositionIndicator
    public var glow: Bool
    public var markers: Bool
    public var dividers: Bool

    public init(valueLabel: Bool = true,
                indicator: PositionIndicator = .dot,
                glow: Bool = true,
                markers: Bool = true,
                dividers: Bool = true) {
        self.valueLabel = valueLabel
        self.indicator = indicator
        self.glow = glow
        self.markers = markers
        self.dividers = dividers
    }

    /// Everything on (dashboard hero bar).
    public static let full = ProgressOverlays()
    /// Lean: indicator + glow, no pill/markers/dividers (Prep landing bar).
    public static let lean = ProgressOverlays(valueLabel: false, indicator: .dot,
                                              glow: true, markers: false, dividers: false)
    /// Bare fill only (task-completion bars).
    public static let bare = ProgressOverlays(valueLabel: false, indicator: .none,
                                              glow: false, markers: false, dividers: false)
}
