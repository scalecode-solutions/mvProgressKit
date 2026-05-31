import SwiftUI

/// The degenerate case of `SegmentedBar`: one segment, no markers — a plain
/// fill bar for task completion ("0/43 packed"). Exists to prove the
/// abstraction collapses cleanly to "just a bar" without feeling bolted-on.
public struct TrackBar: View {
    public var fillFraction: Double
    public var fill: ProgressFill
    public var valueText: AttributedString?
    public var size: BarSize
    public var style: ProgressStyle
    public var overlays: ProgressOverlays

    public init(fillFraction: Double,
                fill: ProgressFill,
                valueText: AttributedString? = nil,
                size: BarSize = .compact,
                style: ProgressStyle = .glass,
                overlays: ProgressOverlays = .bare) {
        self.fillFraction = fillFraction
        self.fill = fill
        self.valueText = valueText
        self.size = size
        self.style = style
        self.overlays = overlays
    }

    public var body: some View {
        SegmentedBar(
            segments: [ProgressSegment(id: 0, fraction: 1.0, fill: fill)],
            markers: [],
            fillFraction: fillFraction,
            valueText: valueText,
            size: size,
            style: style,
            overlays: overlays
        )
    }
}
