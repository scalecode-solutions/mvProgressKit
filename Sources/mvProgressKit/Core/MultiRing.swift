import SwiftUI

/// One concentric ring value (move/exercise/stand-style metrics).
public struct RingValue: Identifiable, Sendable {
    public let id: Int
    public var fillFraction: Double
    public var fill: ProgressFill
    public init(id: Int, fillFraction: Double, fill: ProgressFill) {
        self.id = id
        self.fillFraction = fillFraction
        self.fill = fill
    }
}

/// Concentric rings for parallel values. Built now (Tier 3) to prove the
/// radial renderer *composes* — if N independent values stack cleanly by
/// insetting `ProgressRing`s, multi-value radial is just composition, not a
/// new component.
public struct MultiRing: View {
    public var rings: [RingValue]
    public var lineWidth: CGFloat
    public var spacing: CGFloat
    public var trackColor: Color
    public var style: ProgressStyle

    public init(rings: [RingValue],
                lineWidth: CGFloat = 12,
                spacing: CGFloat = 4,
                trackColor: Color = Color.gray.opacity(0.2),
                style: ProgressStyle = .glass) {
        self.rings = rings
        self.lineWidth = lineWidth
        self.spacing = spacing
        self.trackColor = trackColor
        self.style = style
    }

    public var body: some View {
        ZStack {
            ForEach(Array(rings.enumerated()), id: \.element.id) { index, ring in
                ProgressRing(fillFraction: ring.fillFraction,
                             fill: ring.fill,
                             lineWidth: lineWidth,
                             trackColor: trackColor,
                             span: .full,
                             style: style)
                    .padding(CGFloat(index) * (lineWidth + spacing))
            }
        }
    }
}
