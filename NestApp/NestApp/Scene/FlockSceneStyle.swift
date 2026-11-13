import CoreGraphics

/// Lens, light and material settings for the 3D studio, after the approved prototype. tokens.json has no tokens for these kinds of value.
/// Positions are in tile units (one tile's side), so the studio scales with the tile.
enum FlockSceneStyle {
    /// The camera's vertical field of view, in degrees.
    static let fieldOfView: Float = 30
    /// Where the camera sits and looks, in tile units.
    static let cameraPosition = SIMD3<Float>(0.4, 3.6, 17.5)
    static let cameraTarget = SIMD3<Float>(0.4, 0.2, -1.5)
    /// How far back the lit wall stands, and how wide and tall it is, in tile units.
    static let wallDistance: Float = 24
    static let wallSize = SIMD2<Float>(150, 40)
    /// How high the wall's wash of light reaches, as a share of the wall, and how strong it is at its brightest.
    static let wallWashHeight: Float = 0.07
    static let wallWashStrength: CGFloat = 0.45
    /// Dims the studio's ambient reflections, so light comes from the lights and not the room (a power of two).
    static let environmentLightExponent: Float = -4
    /// The key light's strength, in lux.
    static let keyLightIntensity: Float = 2_400
    /// The cool rim light from behind, in lux.
    static let rimLightIntensity: Float = 2_600
    /// Where the warm key light and the cool rim light shine from, in tile units.
    static let keyLightPosition = SIMD3<Float>(-3, 6, 6)
    static let rimLightPosition = SIMD3<Float>(0.6, 2.4, -7)
    /// The spot that pools light on the floor under the flock: strength in lumens, where it hangs, how far it reaches and how wide.
    static let floorSpotIntensity: Float = 300
    static let floorSpotPosition = SIMD3<Float>(0, 10, 2.2)
    static let floorSpotReach: Float = 26
    static let floorSpotAngle: Float = 50
    /// Glossy ceramic: low roughness under a clear coat.
    static let tileRoughness: Float = 0.3
    static let clearcoatRoughness: Float = 0.04
    /// The lacquered floor.
    static let floorRoughness: Float = 1
    /// How far the floor's pool of light spreads, as a share of the floor.
    static let floorPoolReach: Float = 0.2
    /// How brightly the pool glows; RealityKit's glow scale is strong, so this stays small.
    static let floorPoolStrength: Float = 0.06
    /// How much the floor reflects: only a faint mirror of the tiles.
    static let floorSpecular: Float = 0
    /// How much of the tile's face the glyph covers.
    static let glyphScale: Float = 0.72
    /// The glyph's enamel.
    static let glyphRoughness: Float = 0.34
}
