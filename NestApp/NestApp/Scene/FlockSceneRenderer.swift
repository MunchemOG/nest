import AppKit
import NestKit
import RealityKit

/// Renders the flock scene to an image, for checking that the studio draws.
@MainActor
enum FlockSceneRenderer {
    struct Failure: Error {}

    /// A still of the scene for `statuses`, at `size` points.
    static func render(statuses: [Bird: BirdStatus], size: CGSize) async throws -> NSImage {
        let view = ARView(frame: CGRect(origin: .zero, size: size))
        view.environment.background = .color(NSColor(NestColor.sceneVoid))
        let stage = try await FlockStage()
        stage.arrange(statuses, animated: false)
        view.scene.addAnchor(stage.root)
        let window = NSWindow(contentRect: view.frame, styleMask: .borderless, backing: .buffered, defer: false)
        window.contentView = view
        window.orderFrontRegardless()
        defer { window.close() }
        for _ in 0..<60 { try await Task.sleep(for: .milliseconds(16)) }
        return try await withCheckedThrowingContinuation { continuation in
            view.snapshot(saveToHDR: false) { image in
                if let image { continuation.resume(returning: image) } else { continuation.resume(throwing: Failure()) }
            }
        }
    }

    /// How many of twelve hue bands hold a noticeable share of coloured pixels.
    static func distinctHues(in image: NSImage) -> Int {
        guard let rep = image.tiffRepresentation.flatMap(NSBitmapImageRep.init(data:)) else { return 0 }
        var bands = [Int](repeating: 0, count: 12)
        var total = 0
        for y in stride(from: 0, to: rep.pixelsHigh, by: 4) {
            for x in stride(from: 0, to: rep.pixelsWide, by: 4) {
                guard let colour = rep.colorAt(x: x, y: y)?.usingColorSpace(.sRGB) else { continue }
                total += 1
                if colour.saturationComponent > 0.2, colour.brightnessComponent > 0.4 {
                    bands[min(11, Int(colour.hueComponent * 12))] += 1
                }
            }
        }
        return bands.filter { $0 * 1000 > total }.count
    }
}
