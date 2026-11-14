import Foundation
import NestKit
import Testing
@testable import NestApp

@MainActor
struct SmallSwiftTests {
    @Test func theCloseUpAndTheSmallSwiftShareOneSession() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "HomeModelTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let home = HomeModel()
        home.makeSwiftPage = {
            try? SwiftPageModel(store: SwiftSettingsStore(at: folder.appending(path: "settings.json"), nest: folder), folder: folder, log: nil)
        }

        home.prepareSwift()
        let first = try #require(home.swiftSession)
        home.open(.swift)
        home.prepareSwift()

        #expect(home.swiftSession === first)
        #expect(home.closeUp == .swift)
        #expect(SwiftMiniWindow.id == "swift-mini")
    }
}
