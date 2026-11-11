import XCTest

final class NestWindowUITests: XCTestCase {
    @MainActor
    func testLaunchOpensOneEmptyWindow() throws {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.windows.count, 1)
        let window = app.windows.firstMatch
        let contentTexts = window.staticTexts.matching(NSPredicate(format: "value != %@", window.title))
        XCTAssertEqual(contentTexts.count, 0)
        XCTAssertEqual(window.images.count, 0)
    }
}
