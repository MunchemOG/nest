import Foundation
import Testing
@testable import NestKit

struct CriticalPingsTests {
    static func report(healthy: Bool, weekly: Double = 0.3) -> NestEvent {
        SwiftReport(tasks: [ReportedTask(id: "T-01", ending: .ok, testsAdded: 1)], testsPassing: 40, healthy: healthy,
                    usage: ReportedUsage(weekly: weekly, fiveHour: 0.2, costUSD: 1, reserve: 0.25)).event()
    }

    @Test func aSimulatedRedSendsOneNotificationAndASimulatedAmberSendsNone() async {
        let sent = Sent()
        let pings = CriticalPings(send: sent.add)

        let amber = Self.report(healthy: true, weekly: 0.72)
        let red = Self.report(healthy: false)
        await pings.receive(amber)
        await pings.receive(red)
        await pings.receive(red)

        #expect(sent.notes == [PingNote(title: "Swift: Red", body: "1 of 1 task merged. Nest is broken · 40 tests passing")])
    }

    @Test func onlyEventsMarkedPingReachYou() async throws {
        let sent = Sent()
        let pings = CriticalPings(send: sent.add)
        for event in try DemoDay.events() { await pings.receive(event) }
        #expect(sent.notes.isEmpty)
    }
}

/// Collects the notifications a ping policy sends.
final class Sent: @unchecked Sendable {
    private let lock = NSLock()
    private var stored: [PingNote] = []

    var notes: [PingNote] { lock.withLock { stored } }

    @Sendable func add(_ note: PingNote) async {
        lock.withLock { stored.append(note) }
    }
}
