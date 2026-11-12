import Foundation
@testable import NestKit

extension PetWorld {
    /// 2026-11-11 at 10:00 in Chicago.
    static let fixtureStart = try! Date("2026-11-11T10:00:00-06:00", strategy: .iso8601)

    /// Six Dock icons 100 pt apart along y = 0.
    static let fixturePerches = (0..<6).map { Perch(kind: .dockIcon, point: PetPoint(x: Double($0) * 100, y: 0)) }

    /// Each bird's home in the menu bar, 30 pt apart.
    static let fixtureHomes = Dictionary(uniqueKeysWithValues: Bird.allCases.enumerated().map { index, bird in
        (bird, PetPoint(x: 1000 + 30 * Double(index), y: 900))
    })

    /// A world where the `busy` birds are active at `now` and every other bird is asleep.
    static func fixture(
        now: Date = fixtureStart,
        secondsSinceInput: TimeInterval = 0,
        frontApp: String? = nil,
        hour: Int = 10,
        pointer: PetPoint = PetPoint(x: 300, y: 400),
        pointerSpeed: Double = 0,
        perches: [Perch] = fixturePerches,
        homes: [Bird: PetPoint] = fixtureHomes,
        hideCauses: Set<HideCause> = [],
        busy: Set<Bird> = []
    ) -> PetWorld {
        PetWorld(
            now: now,
            flock: busyFlock(busy, at: now),
            secondsSinceInput: secondsSinceInput,
            frontApp: frontApp,
            hour: hour,
            pointer: pointer,
            pointerSpeed: pointerSpeed,
            perches: perches,
            homes: homes,
            hideCauses: hideCauses
        )
    }

    /// A flock where each of `busy` published one signal at `now`.
    static func busyFlock(_ busy: Set<Bird>, at now: Date) -> FlockState {
        let ts = now.formatted(.iso8601)
        let events = Bird.allCases.filter(busy.contains).map { bird in
            try! EventJSON.decode(EventJSON.make(bird: bird.rawValue, topic: "\(bird.rawValue).pet.seen", ts: ts))
        }
        return FlockState(events: events)
    }
}
