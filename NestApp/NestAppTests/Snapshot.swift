import AppKit
import NestKit
import SwiftUI
import Testing
@testable import NestApp

/// Compares a rendered view with a reference PNG kept next to the tests in `Snapshots/`.
/// A missing or different reference fails the test and leaves the new image in a temp folder.
@MainActor
enum Snapshot {
    static let references = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .appending(path: "Snapshots")

    static let failures = FileManager.default.temporaryDirectory.appending(path: "NestSnapshots")

    static func expect(_ view: some View, named name: String, sourceLocation: SourceLocation = #_sourceLocation) throws {
        try NestFont.registerBundledFonts()
        let content = view
            .padding(NestSpace.s4)
            .background(Color(NestColor.surface0))
            .environment(\.colorScheme, .dark)
        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        let image = try #require(renderer.cgImage, "\(name) did not render", sourceLocation: sourceLocation)
        let png = try #require(NSBitmapImageRep(cgImage: image).representation(using: .png, properties: [:]), sourceLocation: sourceLocation)
        let reference = references.appending(path: "\(name).png")
        guard let expected = try? Data(contentsOf: reference) else {
            Issue.record("No reference for \(name). New image: \(try save(png, name))", sourceLocation: sourceLocation)
            return
        }
        if let difference = try difference(png, expected) {
            Issue.record("\(name) differs from its reference (\(difference)). New image: \(try save(png, name))", sourceLocation: sourceLocation)
        }
    }

    private static func save(_ png: Data, _ name: String) throws -> String {
        try FileManager.default.createDirectory(at: failures, withIntermediateDirectories: true)
        let url = failures.appending(path: "\(name).png")
        try png.write(to: url)
        return url.path
    }

    /// Nil when the two images match within a small tolerance; otherwise what differs.
    private static func difference(_ actual: Data, _ expected: Data) throws -> String? {
        let a = try pixels(actual), b = try pixels(expected)
        guard a.width == b.width, a.height == b.height else {
            return "size \(a.width)×\(a.height), expected \(b.width)×\(b.height)"
        }
        var off = 0
        for i in 0..<a.bytes.count where abs(Int(a.bytes[i]) - Int(b.bytes[i])) > 3 { off += 1 }
        return off * 1000 > a.bytes.count ? "\(off) channels off" : nil
    }

    private static func pixels(_ png: Data) throws -> (width: Int, height: Int, bytes: [UInt8]) {
        let image = try #require(NSBitmapImageRep(data: png)?.cgImage)
        let width = image.width, height = image.height
        var bytes = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = bytes.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(
                data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4,
                space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) else { return false }
            context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        try #require(drawn)
        return (width, height, bytes)
    }
}
