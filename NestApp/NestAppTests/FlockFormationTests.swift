import AppKit
import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct FlockFormationTests {
    static func statuses(_ overrides: [Bird: BirdStatus]) -> [Bird: BirdStatus] {
        Dictionary(uniqueKeysWithValues: Bird.allCases.map { ($0, overrides[$0] ?? .resting) })
    }

    @Test func aWorkingBirdLeadsAndPausedBirdsTrail() {
        let order = FlockFormation.order(Self.statuses([.magpie: .active, .crow: .paused]))
        #expect(order.first == .magpie)
        #expect(order.last == .crow)
        #expect(order.count == 6)
    }

    @Test func ties_keepFlockOrder() {
        #expect(FlockFormation.order(Self.statuses([:])) == Bird.allCases)
        let two = FlockFormation.order(Self.statuses([.owl: .active, .swift: .active]))
        #expect(Array(two.prefix(2)) == [.swift, .owl])
    }

    @Test func theLeadSitsAtThePointOfTheV() {
        #expect(FlockFormation.slot(0) == .zero)
    }

    @Test func armsAlternateAndFanBackAndUp() {
        let left = FlockFormation.slot(1), right = FlockFormation.slot(2)
        #expect(left.x == -right.x && left.x < 0)
        #expect(left.z == right.z && left.z < 0)
        #expect(left.y > 0)
        #expect(FlockFormation.slot(3).z < left.z)
        #expect(FlockFormation.slot(3).x < left.x)
        #expect(FlockFormation.slot(3).y > left.y)
    }

    @Test func stepsComeFromTokens() {
        #expect(FlockFormation.slot(1) == SIMD3(Float(-(NestSpace.s10 + NestSpace.s8)), Float(NestSpace.s5), Float(-NestSpace.s9)))
        #expect(FlockFormation.tileSide == Float(NestSpace.s9))
        #expect(FlockFormation.tileDepth == Float(NestSpace.s6))
    }

    @Test func theWaveRunsDownEachArm() {
        #expect(FlockFormation.wave(at: 0, slot: 0, reduceMotion: false) == 0)
        let quarter = NestMotion.breathe.seconds / 4
        #expect(abs(FlockFormation.wave(at: quarter, slot: 0, reduceMotion: false) - Float(NestSpace.s2)) < 0.001)
        let lag = NestMotion.slow.seconds
        #expect(abs(FlockFormation.wave(at: quarter + lag, slot: 1, reduceMotion: false) - Float(NestSpace.s2)) < 0.001)
    }

    @Test func theWaveStopsUnderReducedMotion() {
        for t in stride(from: 0.0, to: 3.0, by: 0.25) {
            #expect(FlockFormation.wave(at: t, slot: 2, reduceMotion: true) == 0)
        }
    }

    @Test func theSceneRendersTheFlock() async throws {
        try NestFont.registerBundledFonts()
        let image = try await FlockSceneRenderer.render(
            statuses: Self.statuses([.swift: .active, .peacock: .paused]),
            size: CGSize(width: NestSpace.s10 * 6, height: NestSpace.s10 * 4)
        )
        let colours = FlockSceneRenderer.distinctHues(in: image)
        if colours < 4, let tiff = image.tiffRepresentation, let png = NSBitmapImageRep(data: tiff)?.representation(using: .png, properties: [:]) {
            let url = FileManager.default.temporaryDirectory.appending(path: "flock-scene.png")
            try png.write(to: url)
            Issue.record("only \(colours) hues: the tiles did not render. Still: \(url.path)")
        }
    }
}
