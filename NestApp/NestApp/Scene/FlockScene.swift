import AppKit
import Combine
import NestKit
import QuartzCore
import RealityKit
import SwiftUI

/// The flock flying in the studio, behind Home. Decorative: the tags and panels carry the same information.
struct FlockScene: NSViewRepresentable {
    let statuses: [Bird: BirdStatus]
    let mode: String?
    let tags: SceneTags

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    func makeCoordinator() -> Coordinator { Coordinator(tags: tags) }

    func makeNSView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.environment.background = .color(NSColor(NestColor.sceneVoid))
        view.environment.lighting.intensityExponent = FlockSceneStyle.environmentLightExponent
        context.coordinator.attach(to: view, statuses: statuses, mode: mode, reduceMotion: reduceMotion)
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ view: ARView, context: Context) {
        context.coordinator.update(statuses: statuses, mode: mode, reduceMotion: reduceMotion)
    }

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    /// Owns the stage, drives the wave each frame and keeps the tags under their tiles.
    @MainActor
    final class Coordinator {
        private let tags: SceneTags
        private var stage: FlockStage?
        private weak var view: ARView?
        private var statuses: [Bird: BirdStatus] = [:]
        private var mode: String?
        private var reduceMotion = false
        private var frames: (any Cancellable)?

        init(tags: SceneTags) {
            self.tags = tags
        }

        func attach(to view: ARView, statuses: [Bird: BirdStatus], mode: String?, reduceMotion: Bool) {
            self.view = view
            self.statuses = statuses
            self.mode = mode
            self.reduceMotion = reduceMotion
            Task {
                guard let stage = try? await FlockStage() else { return }
                self.stage = stage
                view.scene.addAnchor(stage.root)
                stage.arrange(self.statuses, animated: false)
                try? await stage.setWall(tint: ModeTint.colour(for: self.mode))
                frames = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                    MainActor.assumeIsolated { self?.frame() }
                }
            }
        }

        func update(statuses: [Bird: BirdStatus], mode: String?, reduceMotion: Bool) {
            let moved = FlockFormation.order(statuses) != FlockFormation.order(self.statuses)
            let relit = mode != self.mode
            self.statuses = statuses
            self.mode = mode
            self.reduceMotion = reduceMotion
            if moved { stage?.arrange(statuses, animated: !reduceMotion) }
            if relit, let stage { Task { try? await stage.setWall(tint: ModeTint.colour(for: mode)) } }
        }

        private func frame() {
            guard let stage, let view else { return }
            stage.tick(time: CACurrentMediaTime(), reduceMotion: reduceMotion)
            var points: [Bird: CGPoint] = [:]
            for (bird, world) in stage.tagPoints() {
                guard let point = view.project(world) else { continue }
                points[bird] = view.isFlipped ? point : CGPoint(x: point.x, y: view.bounds.height - point.y)
            }
            if points != tags.points { tags.points = points }
        }
    }
}
