import Foundation
import NestKit

/// A job being set up in the schedule sheet.
struct SwiftScheduleDraft: Equatable, Identifiable {
    /// One id per sheet shown.
    let id = UUID()

    /// When it runs, as the sheet offers it.
    enum When: String, CaseIterable, Hashable {
        case nextGap, tonight, at, nightly, weekly

        var title: String {
            switch self {
            case .nextGap: "Next gap"
            case .tonight: "Tonight"
            case .at: "At a time"
            case .nightly: "Every night"
            case .weekly: "Every week"
            }
        }
    }

    var project: String
    var prompt: String
    var settings: RunSettings
    var ultracode: Bool
    var mode: PermissionMode = .acceptEdits
    var when: When = .nextGap
    var date: Date
    var hour = 1
    var weekday = 2

    /// The timing the sheet's choices add up to.
    var timing: JobTiming {
        switch when {
        case .nextGap: .nextGap
        case .tonight: .tonight
        case .at: .at(date)
        case .nightly: .nightly(hour: hour)
        case .weekly: .weekly(weekday: weekday, hour: hour)
        }
    }

    /// Whether there's enough to schedule.
    var isReady: Bool { !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    /// The job, scheduled at `now` with a fresh id.
    func job(at now: Date = .now) -> SwiftJob {
        SwiftJob(id: String(UUID().uuidString.prefix(8)).lowercased(), project: project,
                 prompt: prompt.trimmingCharacters(in: .whitespacesAndNewlines), settings: settings, ultracode: ultracode,
                 mode: mode, timing: timing, created: now)
    }
}
