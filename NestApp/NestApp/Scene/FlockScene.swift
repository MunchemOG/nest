import AppKit
import Combine
import NestKit
import QuartzCore
import RealityKit
import SwiftUI

/// The flock flying in the studio, behind Home. Decorative: the overview carries the same information.
struct FlockScene: NSViewRepresentable {
    let statuses: [Bird: BirdStatus]

    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    @Environment(\.reduceMotionOverride) private var reduceMotionOverride

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> ARView {
        let view = ARView(frame: .zero)
        view.environment.background = .color(NSColor(NestColor.sceneVoid))
        context.coordinator.attach(to: view, statuses: statuses, reduceMotion: reduceMotion)
        view.setAccessibilityElement(false)
        return view
    }

    func updateNSView(_ view: ARView, context: Context) {
        context.coordinator.update(statuses: statuses, reduceMotion: reduceMotion)
    }

    private var reduceMotion: Bool { reduceMotionOverride ?? systemReduceMotion }

    /// Owns the stage and drives the wave each frame.
    @MainActor
    final class Coordinator {
        private var stage: FlockStage?
        private var statuses: [Bird: BirdStatus] = [:]
        private var reduceMotion = false
        private var frames: (any Cancellable)?

        func attach(to view: ARView, statuses: [Bird: BirdStatus], reduceMotion: Bool) {
            self.statuses = statuses
            self.reduceMotion = reduceMotion
            Task {
                guard let stage = try? await FlockStage() else { return }
                self.stage = stage
                view.scene.addAnchor(stage.root)
                stage.arrange(self.statuses, animated: false)
                frames = view.scene.subscribe(to: SceneEvents.Update.self) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self, let stage = self.stage else { return }
                        stage.tick(time: CACurrentMediaTime(), reduceMotion: self.reduceMotion)
                    }
                }
            }
        }

        func update(statuses: [Bird: BirdStatus], reduceMotion: Bool) {
            let moved = FlockFormation.order(statuses) != FlockFormation.order(self.statuses)
            self.statuses = statuses
            self.reduceMotion = reduceMotion
            if moved { stage?.arrange(statuses, animated: !reduceMotion) }
        }
    }
}
