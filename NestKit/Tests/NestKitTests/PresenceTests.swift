import Foundation
import Testing
@testable import NestKit

struct PresenceTests {
    @Test func flippingTheSwitchMidRunMakesSwiftFinishItsStepAndStop() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        for id in ["T9-01", "T9-02", "T9-03"] { try await queue.add(QueuedTask(id: id, goal: id, doneMeans: id)) }
        let presence = PresenceWatch()
        await presence.receive(.presenceChanged(to: "away", was: "here"))
        // While T9-01's session is working, you arrive and flip the switch.
        let session = """
        id=$(printf '%s' "$1" | grep -o 'Do task [A-Z0-9-]*' | cut -d' ' -f3)
        echo "working on $id"
        while [ ! -f .git/arrived ]; do sleep 0.05; done
        echo "$id" > "$id.txt"; git add -A; git commit -q -m "$id: Add $id.txt"
        printf 'Result: done\\nDid: Added %s.txt.\\n' "$id"
        """
        let arrived = repo.url.appending(path: ".git/arrived")
        let runner = QueueRunner(
            queue: queue,
            runner: ManualRunner(repository: repo.url, session: try repo.script("session", session), tests: ["true"],
                                 watch: { line in
                                     guard line == "working on T9-01" else { return }
                                     Task {
                                         await presence.receive(.presenceChanged(to: "here", was: "away"))
                                         FileManager.default.createFile(atPath: arrived.path, contents: nil)
                                     }
                                 }),
            presence: presence
        )

        let run = try await runner.run()

        #expect(run.outcomes.map(\.task.id) == ["T9-01"], "Swift did not stop after its step")
        #expect(run.outcomes.first?.isDone == true, "Swift dropped its step instead of finishing it")
        #expect(run.paused == "You're here, so Swift stood down.")
        #expect(try await queue.tasks().map(\.state) == [.done, .queued, .queued])
    }

    @Test func swiftDoesNotStartWhileYouAreHere() async throws {
        let repo = try await TempRepo()
        defer { repo.remove() }
        let queue = try TaskQueue(at: repo.url.appending(path: ".git/queue.sqlite"))
        try await queue.add(QueuedTask(id: "T9-01", goal: "One", doneMeans: "One"))
        let presence = PresenceWatch()
        await presence.receive(.presenceChanged(to: "here", was: "away"))
        let runner = QueueRunner(queue: queue, runner: ManualRunner(repository: repo.url, session: ["false"], tests: ["true"]),
                                 presence: presence)
        let run = try await runner.run()
        #expect(run.outcomes.isEmpty)
        #expect(run.paused == "You're here, so Swift stood down.")
    }

    @Test func onlyPresenceEventsChangeWhatTheWatchSees() async throws {
        let presence = PresenceWatch()
        #expect(await presence.current == nil)
        await presence.receive(.presenceChanged(to: "guest", was: "here"))
        await presence.receive(.appAsk(to: "swift", text: "Hello"))
        #expect(await presence.current == "guest")
        #expect(await presence.standsSwiftDown == false, "with a guest, carry on")
        await presence.receive(.presenceChanged(to: "stranger", was: "guest"))
        #expect(await presence.standsSwiftDown == true, "with a stranger, every bird pauses")
    }

    @Test func thePresenceEventFollowsTheContract() {
        let event = NestEvent.presenceChanged(to: "here", was: "away", at: Date(timeIntervalSince1970: 1_794_600_000))
        #expect(event.topic == .owlPresenceChanged)
        #expect(event.kind == .signal)
        #expect(event.sender == .bird(.owl))
        #expect(event.data == ["to": .string("here"), "was": .string("away")])
        #expect(event.undo == nil)
        #expect(event.summary == "Owl saw you arrive")
        #expect(NestEvent.presenceChanged(to: "away", was: "here").summary == "Owl saw you leave")
    }
}
