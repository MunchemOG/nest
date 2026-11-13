/// Lens, light and material settings for the 3D studio. tokens.json has no tokens for these kinds of value.
enum FlockSceneStyle {
    /// The camera's vertical field of view, in degrees.
    static let fieldOfView: Float = 35
    /// The key light's strength, in lux.
    static let keyLightIntensity: Float = 2_500
    /// Glossy ceramic: low roughness under a clear coat.
    static let tileRoughness: Float = 0.25
    /// The lacquered floor.
    static let floorRoughness: Float = 0.15
}
