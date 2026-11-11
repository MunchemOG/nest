import Foundation
import Testing
@testable import NestKit

struct DemoDayTests {
    @Test func wholeDayDecodesInTimeOrder() throws {
        let events = try DemoDay.events()
        #expect((50...70).contains(events.count))
        #expect(events.map(\.ts) == events.map(\.ts).sorted())
    }

    @Test func everyBirdTakesPart() throws {
        let senders = Set(try DemoDay.events().map(\.sender))
        for bird in Bird.allCases {
            #expect(senders.contains(.bird(bird)), "\(bird.name) has no events")
        }
    }

    @Test func idsAreUniqueAndSortByTime() throws {
        let ids = try DemoDay.events().map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids == ids.sorted())
        #expect(ids.allSatisfy { $0.hasPrefix("evt_") && $0.count == 30 })
    }

    @Test func everyTopicIsInTheContract() throws {
        let unknown = try DemoDay.events().filter { !$0.topic.isKnown }.map(\.topic.rawValue)
        #expect(unknown.isEmpty)
    }

    @Test func undoIsPresentExactlyWhenTheContractRequiresIt() throws {
        for event in try DemoDay.events() {
            let required: Bool = switch event.kind {
            case .action: event.topic != .magpieMemoryForgotten
            case .undo, .note: true
            case .signal, .pitch, .report, .ask: false
            }
            #expect((event.undo != nil) == required, "\(event.topic.rawValue) \(event.id)")
        }
    }

    @Test func summariesFollowTheContract() throws {
        for event in try DemoDay.events() {
            #expect(event.summary.count <= 90, "\(event.id)")
            if case .bird(let bird) = event.sender {
                #expect(event.summary.hasPrefix(bird.name), "\(event.id)")
            }
        }
    }

    @Test func causesPointToEarlierEvents() throws {
        var seen: Set<String> = []
        for event in try DemoDay.events() {
            if let cause = event.causedBy {
                #expect(seen.contains(cause), "\(event.id) is caused by \(cause), which is not earlier in the day")
            }
            seen.insert(event.id)
        }
    }
}
