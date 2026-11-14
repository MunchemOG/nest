import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SwiftScheduleTests {
    func page() throws -> (SwiftPageModel, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "SwiftScheduleTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let store = SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: folder)
        return (try SwiftPageModel(store: store, folder: folder, log: nil), folder)
    }

    @Test func whatYouPickInTheSheetBecomesTheJob() {
        var draft = SwiftScheduleDraft(project: "nest", prompt: "  Refactor the paths  ",
                                       settings: RunSettings(model: .opus, effort: .max, subagents: false), ultracode: true,
                                       date: Date(timeIntervalSince1970: 1_800_000_000))
        draft.when = .weekly
        draft.weekday = 4
        draft.hour = 2
        draft.mode = .auto

        let job = draft.job(at: Date(timeIntervalSince1970: 1_790_000_000))

        #expect(job.prompt == "Refactor the paths")
        #expect(job.timing == .weekly(weekday: 4, hour: 2))
        #expect(job.settings.model == .opus)
        #expect(job.ultracode)
        #expect(job.mode == .auto)
        #expect(job.branch == "swift/\(job.id)")
        draft.prompt = "   "
        #expect(!draft.isReady)
    }

    @Test func scheduledJobsAreSavedAndCanBeRemoved() throws {
        let (page, folder) = try page()
        defer { try? FileManager.default.removeItem(at: folder) }
        let draft = SwiftScheduleDraft(project: "nest", prompt: "Tidy the queue", settings: .everyday, ultracode: false, date: .now)

        page.addJob(draft.job())

        #expect(page.jobs.map(\.title) == ["Tidy the queue"])
        #expect(try JobStore(at: folder.appending(path: "jobs.json")).load().map(\.title) == ["Tidy the queue"])
        #expect(page.whenLine(page.jobs[0]) == "Now")
        page.removeJob(page.jobs[0].id)
        #expect(try JobStore(at: folder.appending(path: "jobs.json")).load().isEmpty)
    }
}
