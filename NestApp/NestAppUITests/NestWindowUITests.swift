import XCTest

final class NestWindowUITests: XCTestCase {
    /// Replaces N1-01's "one empty window" test: since N1-17 the window holds the app frame, so only "one window" still holds.
    @MainActor
    func testLaunchOpensOneWindow() throws {
        let app = XCUIApplication.launchedFresh()
        XCTAssertEqual(app.windows.count, 1)
    }
}
