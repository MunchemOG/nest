import XCTest

final class ReportUITests: XCTestCase {
    @MainActor
    func testSwiftsReportDetailsOpenInPlace() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NestReplaySpeed", "3600"]
        app.launch()
        let needsYou = app.descendants(matching: .any)["home.needs-you"].firstMatch
        let details = needsYou.buttons["report.details"]
        XCTAssertTrue(details.waitForExistence(timeout: 30), "Swift's report never reached the needs-you stack")
        let point = needsYou.staticTexts["N1-15 held: the replay test timed out"]
        XCTAssertFalse(point.exists, "the details were open before you asked")
        app.activate()
        details.click()
        XCTAssertTrue(point.waitForExistence(timeout: 3), "the details did not open")
        XCTAssertTrue(app.descendants(matching: .any)["screen.home"].exists, "the details opened somewhere else")
    }
}
