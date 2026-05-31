import Testing
@testable import mvProgressKit

@Test func fullPregnancyPresetBelowWeek37() {
    let input = PregnancyBarInput(completedWeeks: 20, dayOfWeek: 0,
                                  daysUntilDue: 140, progressPercent: 50, gender: .girl)
    #expect(input.phase == .second)
    #expect(input.isLaborReady == false)

    let data = PregnancyBarData.make(for: input)
    #expect(data.segments.count == 1)       // single current-trimester fill
    #expect(data.overtime == nil)           // no overtime before the home stretch
    #expect(abs(data.fillFraction - 0.5) < 0.0001)
}

@Test func homeStretchPresetAtWeek37() {
    let input = PregnancyBarInput(completedWeeks: 37, dayOfWeek: 0,
                                  daysUntilDue: 21, progressPercent: 92, gender: .boy)
    #expect(input.phase == .laborReady)
    #expect(input.isLaborReady)

    let data = PregnancyBarData.make(for: input)
    #expect(data.segments.count == 1)       // single home-stretch fill
    #expect(data.overtime != nil)           // overtime config present
    #expect(data.overtime?.activeWeeks == 0)
    // 36→40 window: week 37 day 0 lands exactly on the 37 mark (0.25).
    #expect(abs(data.fillFraction - 0.25) < 0.0001)
}

@Test func overtimeActivatesAndFillsPastDue() {
    let input = PregnancyBarInput(completedWeeks: 40, dayOfWeek: 3,
                                  daysUntilDue: -10, progressPercent: 100, gender: .girl)
    #expect(input.isOverdue)

    let data = PregnancyBarData.make(for: input)
    #expect((data.overtime?.activeWeeks ?? 0) >= 1)              // overtime activated
    #expect(data.fillFraction >= 1.0)                            // on-time pill full
    #expect((data.overtime?.fraction ?? 0) > 0)                  // overtime filling
}

@Test func overtimeCapsAtTwoWeeks() {
    let input = PregnancyBarInput(completedWeeks: 43, dayOfWeek: 0,
                                  daysUntilDue: -30, progressPercent: 100, gender: .unknown)
    let data = PregnancyBarData.make(for: input)
    #expect(data.overtime?.activeWeeks == 2)                    // capped at 42 weeks
    #expect((data.overtime?.fraction ?? 0) <= 1.0)
}

@Test func genderSelectsPalette() {
    #expect(PregnancyPalette.forGender(.girl) == .girl)
    #expect(PregnancyPalette.forGender(.boy) == .boy)
    #expect(PregnancyPalette.forGender(.unknown) == .default)
}
