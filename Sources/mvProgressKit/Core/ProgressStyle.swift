import SwiftUI

// MARK: - Bar sizing

/// Bundles every height-dependent scalar for a linear bar so the two
/// canonical sizes are a single token, and callers never hand-tune numbers.
public struct BarSize: Equatable, Sendable {
    public var height: CGFloat
    public var dotSize: CGFloat
    public var glowBlur: CGFloat
    public var glowOpacity: Double
    public var dividerWidth: CGFloat
    public var valueCountFont: CGFloat
    public var valueUnitFont: CGFloat
    public var horizontalPadding: CGFloat
    public var markerFont: CGFloat

    public init(height: CGFloat,
                dotSize: CGFloat,
                glowBlur: CGFloat,
                glowOpacity: Double,
                dividerWidth: CGFloat,
                valueCountFont: CGFloat,
                valueUnitFont: CGFloat,
                horizontalPadding: CGFloat,
                markerFont: CGFloat) {
        self.height = height
        self.dotSize = dotSize
        self.glowBlur = glowBlur
        self.glowOpacity = glowOpacity
        self.dividerWidth = dividerWidth
        self.valueCountFont = valueCountFont
        self.valueUnitFont = valueUnitFont
        self.horizontalPadding = horizontalPadding
        self.markerFont = markerFont
    }

    /// 36pt hero bar — matches Clingy's standard dashboard bar.
    public static let standard = BarSize(height: 36, dotSize: 12, glowBlur: 8,
                                         glowOpacity: 0.6, dividerWidth: 2,
                                         valueCountFont: 14, valueUnitFont: 12,
                                         horizontalPadding: 12, markerFont: 8)

    /// 22pt dense bar — matches Clingy's compact dashboard bar.
    public static let compact = BarSize(height: 22, dotSize: 8, glowBlur: 6,
                                        glowOpacity: 0.5, dividerWidth: 1.5,
                                        valueCountFont: 11, valueUnitFont: 10,
                                        horizontalPadding: 8, markerFont: 8)
}

// MARK: - Unfilled track

/// How the unfilled (track) region is painted — a flag every component honors.
public enum UnfilledStyle: Sendable, Equatable {
    /// A fixed neutral track (`ProgressStyle.trackColor`) — today's look.
    case neutral
    /// A faint gradient ghost of the *fill*: each stop blended toward white by
    /// `lighten` (0→fill, 1→white), then dropped to `opacity`. Airy + see-through.
    case shade(lighten: Double, opacity: Double)
}

// MARK: - Shared style tokens

/// Visual tokens shared across every progress component, so a bar, a ring,
/// and a gauge using the same `ProgressStyle` look like one family.
public struct ProgressStyle: Sendable {
    /// Frosted `.ultraThinMaterial` track when true; flat `trackColor` when false.
    public var glassTrack: Bool
    /// Track color (used as the flat track, and as the low-opacity base).
    public var trackColor: Color
    /// How the unfilled region is painted (neutral vs light-shade-of-fill).
    public var unfilled: UnfilledStyle
    /// Stroke cap for radial tracks and step connectors.
    public var lineCap: CGLineCap
    /// Fill animation; `nil` disables animated transitions.
    public var animation: Animation?

    public init(glassTrack: Bool = true,
                trackColor: Color = Color.gray.opacity(0.15),
                unfilled: UnfilledStyle = .neutral,
                lineCap: CGLineCap = .round,
                animation: Animation? = .easeOut(duration: 0.5)) {
        self.glassTrack = glassTrack
        self.trackColor = trackColor
        self.unfilled = unfilled
        self.lineCap = lineCap
        self.animation = animation
    }

    /// Returns a copy with a different unfilled style.
    public func unfilled(_ style: UnfilledStyle) -> ProgressStyle {
        var copy = self
        copy.unfilled = style
        return copy
    }

    /// Default frosted-glass style with a gentle ease-out fill.
    public static let glass = ProgressStyle()
    /// Flat (non-material) track — cheaper, good for small/task bars.
    public static let flat = ProgressStyle(glassTrack: false)
}
