import Foundation
import NestKit

/// Where each bird flies in the V, and how the wave lifts it. Lengths are in points, from the spacing tokens.
enum FlockFormation {
    /// A tile's width and height.
    static let tileSide = Float(NestSpace.s9)
    /// A tile's thickness.
    static let tileDepth = Float(NestSpace.s6)
    /// How far apart neighbouring slots are across.
    static let stepAcross = Float(NestSpace.s10 + NestSpace.s8)
    /// How far each step down an arm goes back.
    static let stepBack = Float(NestSpace.s9)
    /// How much higher each step down an arm flies.
    static let stepUp = Float(NestSpace.s5)
    /// How high the wave lifts a tile.
    static let waveHeight = Float(NestSpace.s2)

    /// The birds from the point of the V back: working birds lead, paused birds trail, ties keep flock order.
    static func order(_ statuses: [Bird: BirdStatus]) -> [Bird] {
        func rank(_ bird: Bird) -> Int {
            switch statuses[bird] ?? .asleep {
            case .active: 0
            case .resting, .asleep: 1
            case .paused: 2
            }
        }
        return Bird.allCases.enumerated()
            .sorted { (rank($0.element), $0.offset) < (rank($1.element), $1.offset) }
            .map(\.element)
    }

    /// How far back along its arm a slot is: 0 for the lead.
    static func depth(of slot: Int) -> Int { (slot + 1) / 2 }

    /// The position of a slot: the lead at the origin, then left and right in turn, each pair further back and a little higher.
    static func slot(_ index: Int) -> SIMD3<Float> {
        let depth = Float(depth(of: index))
        let side: Float = index == 0 ? 0 : (index.isMultiple(of: 2) ? 1 : -1)
        return SIMD3(side * depth * stepAcross, depth * stepUp, -depth * stepBack)
    }

    /// How high the wave lifts a slot at `time` seconds; it runs down each arm one `duration-slow` per step.
    static func wave(at time: TimeInterval, slot: Int, reduceMotion: Bool) -> Float {
        guard !reduceMotion else { return 0 }
        let lagged = time - Double(depth(of: slot)) * NestMotion.slow.seconds
        return Float(sin(2 * Double.pi * lagged / NestMotion.breathe.seconds)) * waveHeight
    }
}
