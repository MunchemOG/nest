import Testing
@testable import NestKit

struct PetRandomTests {
    @Test func sameSeedSameSequence() {
        var a = PetRandom(seed: 7)
        var b = PetRandom(seed: 7)
        #expect((0..<100).map { _ in a.next() } == (0..<100).map { _ in b.next() })
    }

    @Test func differentSeedsDiffer() {
        var a = PetRandom(seed: 7)
        var b = PetRandom(seed: 8)
        #expect((0..<10).map { _ in a.next() } != (0..<10).map { _ in b.next() })
    }

    @Test func aZeroSeedStillVaries() {
        var random = PetRandom(seed: 0)
        #expect(Set((0..<10).map { _ in random.next() }).count == 10)
    }
}
