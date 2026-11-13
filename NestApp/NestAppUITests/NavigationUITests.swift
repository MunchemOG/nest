import XCTest

final class NavigationUITests: XCTestCase {
    static let screens = ["home", "activity", "memory", "settings"]

    @MainActor
    func testTheRailReachesEveryScreen() throws {
        continueAfterFailure = true
        let app = XCUIApplication.launchedFresh()
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].waitForExistence(timeout: 5), "Home is not the first screen\n\(app.debugDescription)")
        for screen in Self.screens.reversed() {
            app.activate()
            app.buttons["rail.\(screen)"].click()
            XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 2), "\(screen) was not reached")
        }
    }

    @MainActor
    func testKeyboardShortcutsReachEveryScreen() throws {
        continueAfterFailure = true
        let app = XCUIApplication.launchedFresh()
        for (index, screen) in Self.screens.enumerated().reversed() {
            app.activate()
            app.typeKey("\(index + 1)", modifierFlags: .command)
            XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 2), "⌘\(index + 1) did not reach \(screen)")
        }
    }
}
