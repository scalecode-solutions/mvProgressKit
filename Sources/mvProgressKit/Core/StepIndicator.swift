import SwiftUI

/// Discrete step/wizard indicator: nodes joined by connectors, each node
/// carrying a `NodeState` (todo / active / done). The deliberate "hard case"
/// for the abstraction — it proves a marker can carry state + a connector, and
/// reuses `ProgressFill`/`ProgressStyle` so it stays in the family.
///
/// Node positions are evenly spaced; only `state` and `label` are read.
public struct StepIndicator: View {
    public var steps: [ProgressMarker]
    public var fill: ProgressFill
    public var trackColor: Color
    public var lineWidth: CGFloat
    public var nodeSize: CGFloat
    public var style: ProgressStyle

    public init(steps: [ProgressMarker],
                fill: ProgressFill,
                trackColor: Color = Color.gray.opacity(0.25),
                lineWidth: CGFloat = 3,
                nodeSize: CGFloat = 28,
                style: ProgressStyle = .flat) {
        self.steps = steps
        self.fill = fill
        self.trackColor = trackColor
        self.lineWidth = lineWidth
        self.nodeSize = nodeSize
        self.style = style
    }

    public var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                node(step)
                if index < steps.count - 1 {
                    connector(filled: step.state == .done)
                }
            }
        }
    }

    @ViewBuilder
    private func node(_ step: ProgressMarker) -> some View {
        let state = step.state ?? .todo
        ZStack {
            switch state {
            case .done:
                Circle().fill(fill.linearStyle())
                Image(systemName: "checkmark")
                    .font(.system(size: nodeSize * 0.4, weight: .bold))
                    .foregroundColor(.white)
            case .active:
                Circle().stroke(fill.linearStyle(), lineWidth: lineWidth)
                Circle().fill(fill.linearStyle()).frame(width: nodeSize * 0.4, height: nodeSize * 0.4)
            case .todo:
                Circle().stroke(trackColor, lineWidth: lineWidth)
                if let label = step.label {
                    Text(label)
                        .font(.system(size: nodeSize * 0.4, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(width: nodeSize, height: nodeSize)
    }

    @ViewBuilder
    private func connector(filled: Bool) -> some View {
        Group {
            if filled {
                Rectangle().fill(fill.linearStyle())
            } else {
                Rectangle().fill(trackColor)
            }
        }
        .frame(height: lineWidth)
        .frame(maxWidth: .infinity)
    }
}
