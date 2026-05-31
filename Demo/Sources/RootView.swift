import SwiftUI
import mvProgressKit

/// Hub + navigation + persistent lean footer (week + gender). Shared state
/// drives every page and survives navigation. Deep-links via launch args.
struct RootView: View {
    @State private var path: [DemoScreen]
    @State private var week: Double
    @State private var gender: Gender
    @State private var coloring: RingColoring
    private let unfilled: UnfilledStyle
    private let overtimeStyle: OvertimeStyle
    private let useGlass: Bool
    private let indicator: PositionIndicator
    private let label: TimelineLabel
    private let useAnimate: Bool
    private let showChrome: Bool

    init() {
        let s = DemoLaunch.initial()
        _path = State(initialValue: s.screen.map { [$0] } ?? [])
        _week = State(initialValue: s.week)
        _gender = State(initialValue: s.gender)
        _coloring = State(initialValue: s.coloring)
        unfilled = s.unfilled
        overtimeStyle = s.overtime
        useGlass = s.glass
        indicator = s.indicator
        label = s.label
        useAnimate = s.animate
        showChrome = s.chrome
    }

    private var style: ProgressStyle {
        var s = ProgressStyle.glass.unfilled(unfilled)
        s.glass = useGlass
        return s
    }

    private var input: PregnancyBarInput {
        PregnancyBarInput(
            completedWeeks: Int(week),
            currentWeek: Int(week) + 1,
            dayOfWeek: Int((week - Double(Int(week))) * 7),
            daysUntilDue: Int((40.0 - week) * 7),
            progressPercent: min(week / 40.0 * 100.0, 100),
            gender: gender
        )
    }

    private var phaseLabel: String {
        switch input.phase {
        case .first:      return "1st Trimester"
        case .second:     return "2nd Trimester"
        case .third:      return "3rd Trimester"
        case .laborReady: return input.isOverdue ? "Labor Ready · OVERDUE" : "Labor Ready"
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            List {
                ForEach(DemoScreen.families, id: \.self) { family in
                    Section(family) {
                        ForEach(DemoScreen.allCases.filter { $0.family == family }) { screen in
                            NavigationLink(value: screen) { Text(screen.title) }
                        }
                    }
                }
            }
            .navigationTitle("mvProgressKit")
            .navigationDestination(for: DemoScreen.self) { screen in
                DetailPage(screen: screen, input: input, coloring: $coloring,
                           style: style, overtimeStyle: overtimeStyle,
                           indicator: indicator, label: label)
                    .navigationTitle(screen.title)
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .preferredColorScheme(.dark)
        .safeAreaInset(edge: .bottom) {
            if showChrome { footer }
        }
        .onAppear {
            if useAnimate {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    week = 42
                }
            }
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Week \(Int(week))").font(.subheadline.bold()).monospacedDigit()
                Spacer()
                Text(phaseLabel)
                    .font(.caption)
                    .foregroundStyle(input.isLaborReady ? .pink : .secondary)
            }
            Slider(value: $week, in: 0...44)
            Picker("Gender", selection: $gender) {
                Text("Girl").tag(Gender.girl)
                Text("Boy").tag(Gender.boy)
                Text("Unknown").tag(Gender.unknown)
            }
            .pickerStyle(.segmented)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial)
    }
}
