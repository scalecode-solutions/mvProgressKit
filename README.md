# mvProgressKit

A SwiftUI progress component kit — one shared foundation so every bar, ring,
and gauge across an app looks like one family. Built standalone (no app
dependency) so it can be iterated and tested in isolation.

## Architecture

```
Sources/mvProgressKit/
├── Core/        ← generic, domain-agnostic renderers + shared style system
└── Pregnancy/   ← thin domain layer (depends on Core, never the reverse)
```

`Core` knows nothing about pregnancies. The `Pregnancy` layer turns primitive
input into `Core` configs. Consuming apps map their own model → the package's
primitive input at the call site.

### Core — two render families, lots of flags

| Family | Component | Notes |
|---|---|---|
| Linear | `SegmentedBar` | proportional segments · markers · dot · value label · glow · dormant overtime tail |
| Linear | `TrackBar` | degenerate single-segment fill (proves the abstraction collapses cleanly) |
| Linear | `StepIndicator` | discrete nodes + connectors with `todo/active/done` state |
| Radial | `ProgressRing` | gradient stroke, full circle |
| Radial | `ProgressGauge` | partial-arc sibling — same renderer, different `ArcSpan` |
| Radial | `MultiRing` | concentric parallel values via composition |

Shared types: `ProgressFill` (solid / linear / angular), `ProgressSegment`,
`ProgressMarker` (+ `NodeState`), `OvertimeConfig`, `ProgressOverlays`
(`.full` / `.lean` / `.bare`), `BarSize` (`.standard` / `.compact`),
`ProgressStyle` (`.glass` / `.flat`).

### Pregnancy layer

- `PregnancyBarInput` — primitives (week, day, daysUntilDue, progress, gender).
- `PregnancyPhase` — `1st/2nd/3rd/laborReady`, boundary at week 37.
- `PregnancyPalette` — gender → trimester ramps + deep-hue `homeStretch` ramps.
- `PregnancyBarData.make(for:)` — picks `.fullPregnancy` (wk 0–36) vs
  `.homeStretch` (wk 37+, with overtime to 42), builds the segments/markers.
- `PregnancyTimelineBar` — the ergonomic SwiftUI view; the live consumer.

## Demo app

Interactive harness: one week slider (0→44) drives the full lifecycle incl. the
week-37 home-stretch switch and overtime past 40; gender picker re-themes live.

The Xcode project is **generated** (never hand-edited):

```sh
cd Demo && xcodegen generate && open mvProgressKitDemo.xcodeproj
```

Add a demo file → re-run `xcodegen generate`. The `.xcodeproj` is gitignored.

## References

`/References` (gitignored) holds cloned SPMs studied for inspiration:
exyte/ProgressIndicatorView (enum-with-associated-values style API),
markhorix/GradientProgressView (data-driven segmented colors).
