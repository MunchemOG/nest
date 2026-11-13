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
        root.scale = SIMD3(repeating: Self.metresPerPoint)
        root.addChild(Self.camera())
        root.addChild(try await Self.floor())
        for light in Self.lights() { root.addChild(light) }
        root.addChild(try await Self.wall(tint: .modeMorning))
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

    /// Re-lights the far wall in a mode's colour.
    func setWall(tint: NestColor) async throws {
        root.children.first { $0.name == "wall" }?.removeFromParent()
        root.addChild(try await Self.wall(tint: tint))
    }

    /// Where under each tile its name tag hangs, in the scene's world space.
    func tagPoints() -> [Bird: SIMD3<Float>] {
        var points: [Bird: SIMD3<Float>] = [:]
        for bird in Bird.allCases {
            guard let bob = bobs[bird] else { continue }
            let below = SIMD3<Float>(0, -FlockFormation.tileSide / 2 - Float(NestSpace.s5), 0)
            points[bird] = bob.convert(position: below, to: nil)
        }
        return points
    }

    /// Lifts each tile on the wave at `time` seconds.
    func tick(time: TimeInterval, reduceMotion: Bool) {
        for (index, bird) in order.enumerated() {
            bobs[bird]?.position.y = FlockFormation.wave(at: time, slot: index, reduceMotion: reduceMotion)
        }
    }

    // MARK: Building

    /// The studio is laid out in points; RealityKit works in metres.
    static let metresPerPoint: Float = 1 / 1000

    /// One tile's side, the unit the studio is laid out in.
    private static var unit: Float { FlockFormation.tileSide }

    private static func camera() -> Entity {
        let camera = PerspectiveCamera()
        camera.camera.fieldOfViewInDegrees = FlockSceneStyle.fieldOfView
        camera.camera.fieldOfViewOrientation = .vertical
        camera.look(at: FlockSceneStyle.cameraTarget * unit, from: FlockSceneStyle.cameraPosition * unit, relativeTo: nil)
        return camera
    }

    /// Where the floor lies: below the lead tile by one step down an arm.
    private static var floorHeight: Float { -(FlockFormation.tileSide / 2 + FlockFormation.stepBack) }

    private static func floor() async throws -> Entity {
        var material = PhysicallyBasedMaterial()
        material.baseColor = .init(tint: NSColor(NestColor.sceneFloor))
        let pool = try await TextureResource(image: pool(), options: .init(semantic: .color))
        material.emissiveColor = .init(color: .white, texture: .init(pool))
        material.emissiveIntensity = FlockSceneStyle.floorPoolStrength
        material.roughness = .init(floatLiteral: FlockSceneStyle.floorRoughness)
        material.specular = .init(floatLiteral: FlockSceneStyle.floorSpecular)
        let size = FlockSceneStyle.wallSize.x * unit
        let floor = ModelEntity(mesh: .generatePlane(width: size, depth: FlockSceneStyle.wallDistance * unit * 2), materials: [material])
        floor.position.y = floorHeight
        return floor
    }

    /// The far wall: near-black, with a soft wash of the mode's light rising from the horizon.
    static func wall(tint: NestColor) async throws -> Entity {
        let texture = try await TextureResource(image: wash(tint), options: .init(semantic: .color))
        var material = UnlitMaterial()
        material.color = .init(tint: .white, texture: .init(texture))
        let size = FlockSceneStyle.wallSize * unit
        let wall = ModelEntity(mesh: .generatePlane(width: size.x, height: size.y), materials: [material])
        wall.name = "wall"
        wall.position = SIMD3(0, floorHeight + size.y / 2, -FlockSceneStyle.wallDistance * unit)
        return wall
    }

    /// The soft pool of light on the floor under the flock, fading to the floor's own dark.
    private static func pool() -> CGImage {
        let size = 512
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let colours = [NSColor(NestColor.surface3).cgColor, NSColor(NestColor.sceneFloor).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: space, colors: colours, locations: [0, 1])!
        let centre = CGPoint(x: size / 2, y: size / 2)
        context.setFillColor(NSColor(NestColor.sceneFloor).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        context.drawRadialGradient(gradient, startCenter: centre, startRadius: 0, endCenter: centre, endRadius: CGFloat(size) * CGFloat(FlockSceneStyle.floorPoolReach), options: [])
        return context.makeImage()!
    }

    /// A wash of `tint` brightest at the horizon's centre, fading up into the studio's dark.
    private static func wash(_ tint: NestColor) -> CGImage {
        let width = 512, height = 256
        let space = CGColorSpace(name: CGColorSpace.sRGB)!
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        context.setFillColor(NSColor(NestColor.sceneVoid).cgColor)
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        let void = NSColor(NestColor.sceneVoid)
        let brightest = void.blended(withFraction: FlockSceneStyle.wallWashStrength, of: NSColor(tint)) ?? void
        let colours = [brightest.cgColor, void.cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: space, colors: colours, locations: [0, 1])!
        let reach = CGFloat(FlockSceneStyle.wallWashHeight) * CGFloat(height)
        context.saveGState()
        context.translateBy(x: CGFloat(width) / 2, y: 0)
        context.scaleBy(x: CGFloat(width) / 2 / reach, y: 1)
        context.drawRadialGradient(gradient, startCenter: .zero, startRadius: 0, endCenter: .zero, endRadius: reach, options: [])
        context.restoreGState()
        return context.makeImage()!
    }

    private static func lights() -> [Entity] {
        let key = DirectionalLight()
        key.light.intensity = FlockSceneStyle.keyLightIntensity
        key.shadow = DirectionalLightComponent.Shadow()
        key.look(at: .zero, from: FlockSceneStyle.keyLightPosition * unit, relativeTo: nil)

        let rim = DirectionalLight()
        rim.light.intensity = FlockSceneStyle.rimLightIntensity
        rim.look(at: .zero, from: FlockSceneStyle.rimLightPosition * unit, relativeTo: nil)

        let spot = SpotLight()
        spot.light.intensity = FlockSceneStyle.floorSpotIntensity
        spot.light.attenuationRadius = FlockSceneStyle.floorSpotReach * unit * Self.metresPerPoint
        spot.light.outerAngleInDegrees = FlockSceneStyle.floorSpotAngle
        spot.look(at: SIMD3(0, floorHeight, 0), from: FlockSceneStyle.floorSpotPosition * unit, relativeTo: nil)
        return [key, rim, spot]
    }

    private static func tile(for bird: Bird) async throws -> Entity {
        var ceramic = PhysicallyBasedMaterial()
        ceramic.baseColor = .init(tint: NSColor(bird.color))
        ceramic.roughness = .init(floatLiteral: FlockSceneStyle.tileRoughness)
        ceramic.clearcoat = .init(floatLiteral: 1)
        ceramic.clearcoatRoughness = .init(floatLiteral: FlockSceneStyle.clearcoatRoughness)
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
        var enamel = PhysicallyBasedMaterial()
        enamel.baseColor = .init(tint: NSColor(NestColor.glyphInk), texture: .init(texture))
        enamel.roughness = .init(floatLiteral: FlockSceneStyle.glyphRoughness)
        enamel.clearcoat = .init(floatLiteral: 1)
        enamel.opacityThreshold = 0.5
        let side = FlockFormation.tileSide * FlockSceneStyle.glyphScale
        return ModelEntity(mesh: .generatePlane(width: side, height: side), materials: [enamel])
    }
}
