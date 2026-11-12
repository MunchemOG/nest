import Foundation
import Testing
@testable import NestKit

struct ActivityTrackerTests {
    let start = Date(timeIntervalSince1970: 0)

    @Test func aStreakSurvivesAFourMinutePause() {
        var tracker = ActivityTracker(breakPause: 300)
        for second in stride(from: 0.0, to: 3000, by: 10) {
            let quiet = (1500...1740).contains(second) ? second - 1500 : 0
            _ = tracker.streak(now: start + second, secondsSinceInput: quiet)
        }
        #expect(tracker.streak(now: start + 3000, secondsSinceInput: 0) == 3000)
    }

    @Test func aFiveMinutePauseResetsTheStreak() {
        var tracker = ActivityTracker(breakPause: 300)
        _ = tracker.streak(now: start, secondsSinceInput: 0)
        #expect(tracker.streak(now: start + 2000, secondsSinceInput: 300) == 0)
        #expect(tracker.streak(now: start + 2010, secondsSinceInput: 0) == 0)
    }

    @Test func aClockJumpResetsTheStreak() {
        var tracker = ActivityTracker(breakPause: 300)
        _ = tracker.streak(now: start, secondsSinceInput: 0)
        #expect(tracker.streak(now: start + 3600, secondsSinceInput: 0) == 0)
    }

    @Test func aFiftyMinuteStreakSurvivesAFourMinutePauseAndResetsAfterAFiveMinuteOne() {
        var tracker = ActivityTracker(breakPause: 300)
        for second in stride(from: 0.0, through: 3000, by: 1) {
            let quiet = (1500...1740).contains(second) ? second - 1500 : 0
            _ = tracker.streak(now: start + second, secondsSinceInput: quiet)
        }
        #expect(tracker.streak(now: start + 3001, secondsSinceInput: 0) == 3001)
        for second in stride(from: 3002.0, through: 3302, by: 1) {
            _ = tracker.streak(now: start + second, secondsSinceInput: second - 3002)
        }
        #expect(tracker.streak(now: start + 3303, secondsSinceInput: 0) == 0)
    }
}
