import XCTest

final class AsleepUITests: XCTestCase {
    @MainActor
    func testWithAnEmptySourceTheAppShowsTheFlockAsleepAndKeepsWorking() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NestSource", "empty"]
        app.launch()
        XCTAssertTrue(app.staticTexts["All six are asleep."].waitForExistence(timeout: 5))
        for screen in ["activity", "memory", "settings", "home"] {
            app.activate()
            app.buttons["rail.\(screen)"].click()
            XCTAssertTrue(app.descendants(matching: .any)["screen.\(screen)"].waitForExistence(timeout: 3), "\(screen) did not open")
        }
        XCTAssertEqual(app.state, .runningForeground)
    }
}
