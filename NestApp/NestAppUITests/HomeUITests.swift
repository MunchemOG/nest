import XCTest

final class HomeUITests: XCTestCase {
    @MainActor
    func testWithTheDemoDayReplayingANewEventAppearsLive() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NestReplaySpeed", "3600"]
        app.launch()
        let feed = app.descendants(matching: .any)["home.feed"].firstMatch
        XCTAssertTrue(feed.waitForExistence(timeout: 5))
        let last = feed.staticTexts["Magpie wrote up today in the daily note"]
        XCTAssertFalse(last.exists, "the day's last event was there before the replay reached it")
        XCTAssertTrue(last.waitForExistence(timeout: 60), "the day's last event never appeared")
    }
}
