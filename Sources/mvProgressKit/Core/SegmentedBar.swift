import SwiftUI

/// The workhorse linear bar: proportional segments, optional markers, a
/// position dot, a value label, a glow, and an optional dormant overtime tail.
///
/// Everything is data-driven — `segments`/`markers` come from a factory (e.g.
/// the Pregnancy layer), so this view knows nothing about trimesters or weeks.
/// `TrackBar` is its degenerate single-segment case; the dashboard timeline and
/// the home-stretch bar are both just different segment/marker data.
public struct SegmentedBar: View {
    public var segments: [ProgressSegment]
    public var markers: [ProgressMarker]
    /// Overall fill, 0...1 across the full drawn span (segments + any tail).
    public var fillFraction: Double
    public var overtime: OvertimeConfig?
    /// Caller-supplied label content (e.g. "20 days to go", "+3 days").
    public var valueText: AttributedString?
    public var size: BarSize
    public var style: ProgressStyle
    public var overlays: ProgressOverlays

    public init(segments: [ProgressSegment],
                markers: [ProgressMarker] = [],
                fillFraction: Double,
                overtime: OvertimeConfig? = nil,
                valueText: AttributedString? = nil,
                size: BarSize = .standard,
                style: ProgressStyle = .glass,
                overlays: ProgressOverlays = .full) {
        self.segments = segments
        self.markers = markers
        self.fillFraction = fillFraction
        self.overtime = overtime
        self.valueText = valueText
        self.size = size
        self.style = style
        self.overlays = overlays
    }

    private var radius: CGFloat { size.height / 2 }
    private var fill: Double { min(max(fillFraction, 0), 1) }

    /// Cumulative start fraction for each segment.
    private var offsets: [(seg: ProgressSegment, start: Double)] {
        var cum = 0.0
        return segments.map { seg in
            defer { cum += seg.fraction }
            return (seg, cum)
        }
    }

    /// Lead color of whichever segment the fill currently sits in (dot/glow tint).
    private var fillColor: Color {
        for (seg, start) in offsets where fill <= start + seg.fraction {
            return seg.fill.leadColor
        }
        return segments.last?.fill.leadColor ?? .accentColor
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .leading) {
                track(width: w)
                fillBar(width: w)
                    .modifier(AnimateFill(animation: style.animation, value: fill))
                if overlays.markers { markerTicks(width: w) }
                if let ot = overtime { dueMarker(ot, width: w) }
                if overlays.positionDot { positionDot(width: w) }
                if overlays.valueLabel, let valueText { valueLabelView(valueText) }
            }
            .frame(height: size.height)
        }
        .frame(height: size.height)
    }

    // MARK: Track (glass + segment tints + dividers)

    @ViewBuilder
    private func track(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            // Base track
            Group {
                if style.glassTrack {
                    RoundedRectangle(cornerRadius: radius).fill(.ultraThinMaterial)
                } else {
                    RoundedRectangle(cornerRadius: radius).fill(style.trackColor)
                }
            }
            .frame(height: size.height)

            // Faint per-segment tints
            HStack(spacing: 0) {
                ForEach(offsets, id: \.seg.id) { (seg, _) in
                    (seg.tint ?? seg.fill.leadColor).opacity(0.15)
                        .frame(width: width * seg.fraction)
                }
                Spacer(minLength: 0) // reserved tail (overtime) stays clear
            }
            .frame(height: size.height)
            .clipShape(RoundedRectangle(cornerRadius: radius))

            // Dividers between segments
            if overlays.dividers {
                ForEach(offsets.dropFirst().map { $0.start }, id: \.self) { boundary in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: size.dividerWidth, height: size.height)
                        .offset(x: width * boundary - size.dividerWidth / 2)
                }
            }
        }
    }

    // MARK: Fill (per-segment gradients clipped to fill, with glow)

    @ViewBuilder
    private func fillBar(width: CGFloat) -> some View {
        let bar = HStack(spacing: 0) {
            ForEach(offsets, id: \.seg.id) { (seg, start) in
                let filled = min(max(fill - start, 0), seg.fraction)
                if filled > 0 {
                    Rectangle()
                        .fill(seg.fill.linearStyle())
                        .frame(width: width * filled)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(height: size.height)
        .clipShape(RoundedRectangle(cornerRadius: radius))

        ZStack(alignment: .leading) {
            if overlays.glow {
                bar.blur(radius: size.glowBlur).opacity(size.glowOpacity)
            }
            bar
        }
    }

    // MARK: Markers

    @ViewBuilder
    private func markerTicks(width: CGFloat) -> some View {
        ForEach(markers) { marker in
            VStack(spacing: 2) {
                Rectangle()
                    .fill(Color.white.opacity(0.4))
                    .frame(width: 1, height: size.height * 0.4)
                if let label = marker.label {
                    Text(label)
                        .font(.system(size: size.markerFont, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .offset(x: width * marker.position - 0.5)
        }
    }

    @ViewBuilder
    private func dueMarker(_ ot: OvertimeConfig, width: CGFloat) -> some View {
        Rectangle()
            .fill(Color.white.opacity(0.85))
            .frame(width: size.dividerWidth, height: size.height)
            .offset(x: width * ot.dueAnchor - size.dividerWidth / 2)
    }

    // MARK: Position dot

    @ViewBuilder
    private func positionDot(width: CGFloat) -> some View {
        if fill > 0.02 && fill < 0.98 {
            Circle()
                .fill(Color.white)
                .frame(width: size.dotSize, height: size.dotSize)
                .shadow(color: fillColor.opacity(0.5), radius: size.dotSize / 3)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .offset(x: width * fill - size.dotSize / 2)
                .modifier(AnimateFill(animation: style.animation, value: fill))
        }
    }

    // MARK: Value label

    @ViewBuilder
    private func valueLabelView(_ text: AttributedString) -> some View {
        HStack {
            Text(text)
            Spacer()
        }
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.4), radius: 2, y: 1)
        .padding(.horizontal, size.horizontalPadding)
        .frame(height: size.height)
    }
}

/// Applies the style's fill animation to a value, or none if `animation == nil`.
private struct AnimateFill: ViewModifier, @unchecked Sendable {
    let animation: Animation?
    let value: Double
    func body(content: Content) -> some View {
        if let animation {
            content.animation(animation, value: value)
        } else {
            content
        }
    }
}
