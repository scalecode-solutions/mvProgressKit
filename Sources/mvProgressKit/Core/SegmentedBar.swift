import SwiftUI

/// The workhorse linear bar: proportional segments, optional markers, a
/// position dot, a value label, a glow, and split-pill overtime.
///
/// Data-driven — `segments`/`markers` come from a factory (e.g. the Pregnancy
/// layer), so this view knows nothing about trimesters or weeks. With
/// `style.glass` the track + fill render as real Liquid Glass capsules inside a
/// `GlassEffectContainer`; otherwise they're gradient/shade fills. Overlays
/// (markers, dot, value) draw on top of either backing.
public struct SegmentedBar: View {
    public var segments: [ProgressSegment]
    public var markers: [ProgressMarker]
    public var fillFraction: Double
    public var overtime: OvertimeConfig?
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

    @Namespace private var glassNS

    private var radius: CGFloat { size.height / 2 }
    private var fill: Double { min(max(fillFraction, 0), 1) }

    private var offsets: [(seg: ProgressSegment, start: Double)] {
        var cum = 0.0
        return segments.map { seg in
            defer { cum += seg.fraction }
            return (seg, cum)
        }
    }

    private var fillColor: Color {
        for (seg, start) in offsets where fill <= start + seg.fraction {
            return seg.fill.leadColor
        }
        return segments.last?.fill.leadColor ?? .accentColor
    }

    public var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let mainW = overtime?.resolvedMainWidth ?? 1.0
            let mainPx = w * mainW
            let showOT = overtime?.isShown ?? false
            let gapPx = w * (overtime?.gap ?? 0)
            let otStart = mainPx + gapPx
            let otWidth = max(w - otStart, 0)

            ZStack(alignment: .leading) {
                if style.glass {
                    glassLayer(mainPx: mainPx, otStart: otStart, otWidth: otWidth, showOT: showOT)
                } else {
                    mainRegion(width: mainPx, squaredRight: showOT)
                    if showOT, let ot = overtime {
                        overtimeRegion(ot, width: otWidth).offset(x: otStart)
                    }
                }
                overlayLayer(width: mainPx)
            }
            .frame(height: size.height)
            .animation(style.animation, value: mainW)
        }
        .frame(height: size.height)
    }

    // MARK: Overlays (markers / dot / value) — shared across backings

    @ViewBuilder
    private func overlayLayer(width: CGFloat) -> some View {
        if overlays.markers { markerTicks(width: width) }
        positionIndicator(width: width)
        if overlays.valueLabel, let valueText { valueLabelView(valueText) }
    }

    // MARK: Liquid Glass backing

    @ViewBuilder
    private func glassLayer(mainPx: CGFloat, otStart: CGFloat,
                            otWidth: CGFloat, showOT: Bool) -> some View {
        GlassEffectContainer(spacing: size.height * 0.4) {
            ZStack(alignment: .leading) {
                glassRegion(width: mainPx, frac: fill,
                            left: true, right: !showOT, tint: fillColor, idSuffix: "main")
                if showOT, let ot = overtime {
                    glassRegion(width: otWidth, frac: ot.fraction,
                                left: false, right: true,
                                tint: segments.last?.fill.leadColor ?? .accentColor,
                                idSuffix: "ot")
                        .offset(x: otStart)
                }
            }
        }
        .animation(style.animation, value: showOT)
        .modifier(AnimateFill(animation: style.animation, value: fill))
    }

    @ViewBuilder
    private func glassRegion(width: CGFloat, frac: Double,
                             left: Bool, right: Bool, tint: Color, idSuffix: String) -> some View {
        let shape = pill(left: left, right: right)
        let f = min(max(frac, 0), 1)
        ZStack(alignment: .leading) {
            shape.fill(.clear).glassEffect(.regular, in: shape)
                .glassEffectID("track-\(idSuffix)", in: glassNS)
            Capsule().fill(.clear)
                .glassEffect(.regular.tint(tint), in: Capsule())
                .frame(width: max(width * f, size.height), height: size.height)
                .opacity(f > 0.001 ? 1 : 0)
                .glassEffectID("fill-\(idSuffix)", in: glassNS)
        }
        .frame(width: width, height: size.height, alignment: .leading)
    }

    // MARK: Standard backing

    @ViewBuilder
    private func mainRegion(width: CGFloat, squaredRight: Bool) -> some View {
        let shape = pill(left: true, right: !squaredRight)
        ZStack(alignment: .leading) {
            trackLayer(width: width).clipShape(shape)
            fillLayer(width: width).clipShape(shape)
                .modifier(AnimateFill(animation: style.animation, value: fill))
        }
        .frame(width: width, height: size.height, alignment: .leading)
    }

    @ViewBuilder
    private func overtimeRegion(_ ot: OvertimeConfig, width: CGFloat) -> some View {
        let shape = pill(left: false, right: true)
        let otFill = segments.last?.fill ?? .solid(.accentColor)
        let bar = HStack(spacing: 0) {
            Rectangle().fill(otFill.linearStyle()).frame(width: width * ot.fraction)
            Spacer(minLength: 0)
        }
        .frame(width: width, height: size.height)

        ZStack(alignment: .leading) {
            Rectangle().fill(trackStyle(for: otFill)).clipShape(shape)
            ZStack {
                if overlays.glow { bar.blur(radius: size.glowBlur).opacity(size.glowOpacity) }
                bar
            }
            .clipShape(shape)
        }
        .frame(width: width, height: size.height, alignment: .leading)
        .modifier(AnimateFill(animation: style.animation, value: ot.fraction))
    }

    private func pill(left: Bool, right: Bool) -> UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: left ? radius : 0,
            bottomLeadingRadius: left ? radius : 0,
            bottomTrailingRadius: right ? radius : 0,
            topTrailingRadius: right ? radius : 0
        )
    }

    // MARK: Track + fill layers (standard)

    private var showsBase: Bool {
        switch style.unfilled {
        case .neutral:               return true
        case .shade(_, _, let base): return base
        }
    }

    @ViewBuilder
    private func trackLayer(width: CGFloat) -> some View {
        ZStack(alignment: .leading) {
            if showsBase {
                Group {
                    if style.glassTrack {
                        Rectangle().fill(.ultraThinMaterial)
                    } else {
                        Rectangle().fill(style.trackColor)
                    }
                }
            }
            HStack(spacing: 0) {
                ForEach(offsets, id: \.seg.id) { (seg, _) in
                    Rectangle().fill(trackStyle(for: seg.fill, tint: seg.tint))
                        .frame(width: width * seg.fraction)
                }
                Spacer(minLength: 0)
            }
            if overlays.dividers {
                ForEach(offsets.dropFirst().map { $0.start }, id: \.self) { boundary in
                    Rectangle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: size.dividerWidth, height: size.height)
                        .offset(x: width * boundary - size.dividerWidth / 2)
                }
            }
        }
        .frame(width: width, height: size.height)
    }

    @ViewBuilder
    private func fillLayer(width: CGFloat) -> some View {
        let bar = HStack(spacing: 0) {
            ForEach(offsets, id: \.seg.id) { (seg, start) in
                let filled = min(max(fill - start, 0), seg.fraction)
                if filled > 0 {
                    Rectangle().fill(seg.fill.linearStyle()).frame(width: width * filled)
                }
            }
            Spacer(minLength: 0)
        }
        .frame(width: width, height: size.height)

        ZStack {
            if overlays.glow { bar.blur(radius: size.glowBlur).opacity(size.glowOpacity) }
            bar
        }
    }

    // MARK: Overlay pieces

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
    private func positionIndicator(width: CGFloat) -> some View {
        if fill > 0.02 && fill < 0.98, overlays.indicator != .none {
            indicatorContent
                .frame(width: size.height, height: size.height)
                .shadow(color: fillColor.opacity(0.5), radius: size.dotSize / 3)
                .shadow(color: .black.opacity(0.2), radius: 1, y: 0.5)
                .offset(x: width * fill - size.height / 2)
                .modifier(AnimateFill(animation: style.animation, value: fill))
        }
    }

    @ViewBuilder
    private var indicatorContent: some View {
        switch overlays.indicator {
        case .none:
            EmptyView()
        case .dot:
            Circle().fill(Color.white).frame(width: size.dotSize, height: size.dotSize)
        case .symbol(let name):
            Image(systemName: name)
                .font(.system(size: size.height * 0.55, weight: .bold))
                .foregroundStyle(.white)
        }
    }

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

    /// Unfilled-track paint for a fill, per the style's `UnfilledStyle`.
    private func trackStyle(for fill: ProgressFill, tint: Color? = nil) -> AnyShapeStyle {
        switch style.unfilled {
        case .neutral:
            return AnyShapeStyle((tint ?? fill.leadColor).opacity(0.15))
        case .shade(let lighten, let opacity, _):
            return AnyShapeStyle(fill.track(lighten: lighten, opacity: opacity).linearStyle())
        }
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
