import SwiftUI

/// A partial-arc "dial" — `ProgressRing` with a `.gauge` span plus a center
/// value. Built now (Tier 3) purely to prove the radial renderer parametrizes
/// arc sweep; if this works, every full/partial radial shape is a `span` flag.
public struct ProgressGauge<Center: View>: View {
    public var fillFraction: Double
    public var fill: ProgressFill
    public var lineWidth: CGFloat
    public var trackColor: Color
    public var span: ArcSpan
    public var style: ProgressStyle
    public var center: () -> Center

    public init(fillFraction: Double,
                fill: ProgressFill,
                lineWidth: CGFloat = 14,
                trackColor: Color = Color.gray.opacity(0.2),
                span: ArcSpan = .gauge,
                style: ProgressStyle = .glass,
                @ViewBuilder center: @escaping () -> Center) {
        self.fillFraction = fillFraction
        self.fill = fill
        self.lineWidth = lineWidth
        self.trackColor = trackColor
        self.span = span
        self.style = style
        self.center = center
    }

    public var body: some View {
        ProgressRing(fillFraction: fillFraction,
                     fill: fill,
                     lineWidth: lineWidth,
                     trackColor: trackColor,
                     span: span,
                     style: style,
                     center: center)
    }
}

public extension ProgressGauge where Center == EmptyView {
    init(fillFraction: Double,
         fill: ProgressFill,
         lineWidth: CGFloat = 14,
         trackColor: Color = Color.gray.opacity(0.2),
         span: ArcSpan = .gauge,
         style: ProgressStyle = .glass) {
        self.init(fillFraction: fillFraction, fill: fill, lineWidth: lineWidth,
                  trackColor: trackColor, span: span, style: style) { EmptyView() }
    }
}
