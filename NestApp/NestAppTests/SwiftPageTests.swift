import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SwiftPageTests {
    func page() throws -> (SwiftPageModel, URL) {
        let folder = FileManager.default.temporaryDirectory.appending(path: "SwiftPageTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let model = SwiftPageModel(queue: try TaskQueue(at: folder.appending(path: "queue.sqlite")),
                                   rules: BudgetRules(reserve: 0.25))
        return (model, folder)
    }

    @Test func youCanAddATaskByChatAndSeeItInTheQueue() async throws {
        let (model, folder) = try page()
        defer { try? FileManager.default.removeItem(at: folder) }

        await model.send("Add a task: show the queue count on Home. Done means: a test sees 3 when 3 are queued")

        #expect(model.tonight.map(\.id) == ["Y-01"])
        #expect(model.tonight.first?.goal == "Show the queue count on Home")
        #expect(model.tonight.first?.doneMeans == "A test sees 3 when 3 are queued")
        #expect(model.messages.map(\.sender) == [.you, .bird(.swift)])
        #expect(model.messages.last?.text == "Queued Y-01: Show the queue count on Home.")
    }

    @Test func aTaskWithNoTestGetsAQuestionInstead() async throws {
        let (model, folder) = try page()
        defer { try? FileManager.default.removeItem(at: folder) }
        await model.send("Add a task: make Home nicer")
        #expect(model.tonight.isEmpty)
        #expect(model.messages.last?.text == "A task needs a test before I spend on it. What does done mean for \"Make Home nicer\"?")
    }

    @Test func theBoundariesSayWhatSwiftKeepsTo() throws {
        let (model, folder) = try page()
        defer { try? FileManager.default.removeItem(at: folder) }
        #expect(model.boundaries == ["Keeps 25% of the week back for you.", "Stands down when you arrive.",
                                     "Merges only when every test passes."])
    }
}
