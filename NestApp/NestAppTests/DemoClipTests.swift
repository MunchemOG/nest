import AVFoundation
import Foundation
import Testing

struct DemoClipTests {
    static let clip = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appending(path: "design/demo/shell-demo-day.mov")

    @Test func theDemoClipExistsAndRunsAboutThirtySeconds() async throws {
        #expect(FileManager.default.fileExists(atPath: Self.clip.path))
        let asset = AVURLAsset(url: Self.clip)
        let seconds = try await asset.load(.duration).seconds
        #expect((25...35).contains(seconds), "the clip runs \(seconds) s")
        let video = try await asset.loadTracks(withMediaType: .video)
        #expect(!video.isEmpty)
    }
}
