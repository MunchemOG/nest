import AppKit
import NestKit
import RealityKit

/// The 3D studio: a lacquered floor, soft light, and the six birds as glossy tiles flying in a V.
@MainActor
final class FlockStage {
    /// Everything in the scene, in points (scaled to metres here).
    let root = AnchorEntity(world: .zero)
    private var slots: [Bird: Entity] = [:]
    private var bobs: [Bird: Entity] = [:]
    private var order = Bird.allCases

    /// Builds the studio and the six tiles.
    init() async throws {
        root.scale = SIMD3(repeating: 1 / 1000)
        root.addChild(Self.camera())
        root.addChild(Self.floor())
        root.addChild(Self.keyLight())
        for bird in Bird.allCases {
            let slot = Entity()
            let bob = Entity()
            bob.addChild(try await Self.tile(for: bird))
            slot.addChild(bob)
            root.addChild(slot)
            slots[bird] = slot
            bobs[bird] = bob
        }
        arrange(order, animated: false)
    }

    /// Moves each bird to its place in the V for these statuses.
    func arrange(_ statuses: [Bird: BirdStatus], animated: Bool) {
        arrange(FlockFormation.order(statuses), animated: animated)
    }

    private func arrange(_ order: [Bird], animated: Bool) {
        self.order = order
        for (index, bird) in order.enumerated() {
            guard let slot = slots[bird] else { continue }
            let place = Transform(translation: FlockFormation.slot(index))
            if animated {
                slot.move(to: place, relativeTo: root, duration: NestMotion.slow.seconds, timingFunction: .easeInOut)
            } else {
                slot.transform = place
            }
        }
    }

    /// Lifts each tile on the wave at `time` seconds.
    func tick(time: TimeInterval, reduceMotion: Bool) {
        for (index, bird) in order.enumerated() {
            bobs[bird]?.position.y = FlockFormation.wave(at: time, slot: index, reduceMotion: reduceMotion)
        }
    }

    // MARK: Building

    private static func camera() -> Entity {
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = FlockSceneStyle.fieldOfView
        let back = FlockFormation.step * 2
        camera.look(
            at: SIMD3(0, 0, -back / 2),
            from: SIMD3(0, FlockFormation.step * 1.5, FlockFormation.step * 5),
            relativeTo: nil
        )
        return camera
    }

    private static func floor() -> Entity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: NSColor(NestColor.sceneFloor))
        material.roughness = .init(floatLiteral: FlockSceneStyle.floorRoughness)
        let floor = ModelEntity(
            mesh: .generatePlane(width: FlockFormation.step * 100, depth: FlockFormation.step * 100),
            materials: [material]
        )
        floor.position.y = -(FlockFormation.tileSide / 2 + FlockFormation.step / 2)
        return floor
    }

    private static func keyLight() -> Entity {
        let light = DirectionalLight()
        light.light.intensity = FlockSceneStyle.keyLightIntensity
        light.shadow = DirectionalLightComponent.Shadow()
        light.look(at: .zero, from: SIMD3(-FlockFormation.step, FlockFormation.step * 4, FlockFormation.step * 3), relativeTo: nil)
        return light
    }

    private static func tile(for bird: Bird) async throws -> Entity {
        var ceramic = PhysicallyBasedMaterial()
        ceramic.baseColor = .init(tint: NSColor(bird.color))
        ceramic.roughness = .init(floatLiteral: FlockSceneStyle.tileRoughness)
        ceramic.clearcoat = .init(floatLiteral: 1)
        ceramic.clearcoatRoughness = .init(floatLiteral: FlockSceneStyle.tileRoughness)
        let side = FlockFormation.tileSide
        let body = ModelEntity(
            mesh: .generateBox(width: side, height: side, depth: FlockFormation.tileDepth, cornerRadius: Float(NestRadius.tile)),
            materials: [ceramic]
        )
        body.components.set(GroundingShadowComponent(castsShadow: true))

        let tile = Entity()
        tile.addChild(body)
        if let glyph = try await glyph(for: bird) {
            glyph.position.z = FlockFormation.tileDepth / 2 + Float(NestSpace.s1)
            tile.addChild(glyph)
        }
        return tile
    }

    /// The bird's glyph in black enamel, one piece floating just in front of the tile.
    private static func glyph(for bird: Bird) async throws -> Entity? {
        guard let image = NSImage(named: bird.glyph.menuBar),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else { return nil }
        let texture = try await TextureResource(image: cgImage, options: .init(semantic: .color))
        var enamel = UnlitMaterial()
        enamel.color = .init(tint: NSColor(NestColor.glyphInk), texture: .init(texture))
        enamel.opacityThreshold = 0.5
        let side = FlockFormation.tileSide
        return ModelEntity(mesh: .generatePlane(width: side, height: side), materials: [enamel])
    }
}
