import CoreGraphics
import NestKit
import Observation

/// Where each bird's name tag sits on screen, under its tile, updated as the flock moves.
@Observable
@MainActor
final class SceneTags {
    /// Each bird's tag point in the scene view's coordinates, top-left origin.
    var points: [Bird: CGPoint] = [:]
}
