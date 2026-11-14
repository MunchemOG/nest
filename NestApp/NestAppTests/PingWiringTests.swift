import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct PingWiringTests {
    @Test func homeHandsARedReportToThePingsAndNothingElse() async throws {
        let sent = SentNotes()
        let model = HomeModel()
        model.pings = CriticalPings(send: sent.add)
        try DemoDay.events().forEach(model.receive)
        let red = SwiftReport(tasks: [], testsPassing: 3, healthy: false,
                              usage: ReportedUsage(weekly: 0.1, fiveHour: 0.1, costUSD: 0, reserve: 0.25)).event()
        model.receive(red)
        #expect(await HomeModelTests.eventually { sent.count == 1 })
        #expect(sent.count == 1)
    }
}

/// Counts the notifications Home's pings send.
final class SentNotes: @unchecked Sendable {
    private let lock = NSLock()
    private var stored = 0

    var count: Int { lock.withLock { stored } }

    @Sendable func add(_ note: PingNote) async {
        lock.withLock { stored += 1 }
    }
}
