import XCTest

final class TimelineUITests: XCTestCase {
    @MainActor
    func testFilteringAndSearchingTheTimeline() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES", "-NestReplaySpeed", "100000"]
        app.launch()
        app.activate()
        app.buttons["rail.activity"].click()
        let rows = app.descendants(matching: .any).matching(identifier: "timeline.row")
        XCTAssertTrue(rows.firstMatch.waitForExistence(timeout: 10))
        app.activate()
        app.buttons["timeline.filter.owl"].click()
        let owlOnly = NSPredicate(format: "count > 0")
        expectation(for: owlOnly, evaluatedWith: app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Owl '")))
        waitForExpectations(timeout: 5)
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Wren moved'")).count, 0)
        app.buttons["timeline.filter.all"].click()
        let search = app.textFields["timeline.search"]
        search.click()
        search.typeText("match-sheet-q13")
        XCTAssertTrue(app.staticTexts["Wren moved match-sheet-q13.csv to Robotics / Scouting"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH 'Owl '")).count, 0)
    }
}
