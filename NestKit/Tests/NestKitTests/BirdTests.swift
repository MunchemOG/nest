import Testing
@testable import NestKit

struct BirdTests {
    struct Expected: Sendable, CustomTestStringConvertible {
        let id: String
        let name: String
        let role: String
        let color: NestColor
        let tile: String
        let menuBar: String

        var testDescription: String { id }
    }

    /// Hand-copied from `docs/master-plan.md`, `docs/event-bus.md` and `design/tokens.json`.
    static let flock: [Expected] = [
        Expected(id: "wren", name: "Wren", role: "Keeper of space", color: NestColor(rgb: 0xd2ae8a), tile: "wren-tile", menuBar: "wren-menubar"),
        Expected(id: "swift", name: "Swift", role: "Builder", color: NestColor(rgb: 0x6e9bd3), tile: "swift-tile", menuBar: "swift-menubar"),
        Expected(id: "crow", name: "Crow", role: "Inventor", color: NestColor(rgb: 0x8e86d6), tile: "crow-tile", menuBar: "crow-menubar"),
        Expected(id: "owl", name: "Owl", role: "Eyes", color: NestColor(rgb: 0xd4a954), tile: "owl-tile", menuBar: "owl-menubar"),
        Expected(id: "magpie", name: "Magpie", role: "Second brain", color: NestColor(rgb: 0xd47a93), tile: "magpie-tile", menuBar: "magpie-menubar"),
        Expected(id: "peacock", name: "Peacock", role: "Showcase", color: NestColor(rgb: 0xc27bb8), tile: "peacock-tile", menuBar: "peacock-menubar"),
    ]

    @Test func theFlockIsExactlySixBirdsInOrder() {
        #expect(Bird.allCases.map(\.rawValue) == Self.flock.map(\.id))
    }

    @Test(arguments: flock)
    func birdResolvesEveryProperty(_ expected: Expected) throws {
        let bird = try #require(Bird(rawValue: expected.id), "no bird with the event-bus id \(expected.id)")
        #expect(bird.name == expected.name)
        #expect(bird.role == expected.role)
        #expect(bird.color == expected.color)
        #expect(bird.glyph.tile == expected.tile)
        #expect(bird.glyph.menuBar == expected.menuBar)
    }

    @Test func everyBirdHasItsOwnColour() {
        #expect(Set(Bird.allCases.map(\.color)).count == Bird.allCases.count)
    }

    @Test func eventBusNamesThatAreNotBirdsAreRejected() {
        #expect(Bird(rawValue: "you") == nil)
        #expect(Bird(rawValue: "app") == nil)
        #expect(Bird(rawValue: "Wren") == nil)
    }
}
