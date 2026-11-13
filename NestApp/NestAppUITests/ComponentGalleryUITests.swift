import XCTest

final class ComponentGalleryUITests: XCTestCase {
    static let components = [
        "gallery.type",
        "gallery.button",
        "gallery.tag",
        "gallery.status-pill",
        "gallery.avatar",
        "gallery.card",
        "gallery.panel-solid",
        "gallery.panel-floating",
        "gallery.activity-row",
        "gallery.chat-bubble",
        "gallery.typing",
        "gallery.composer",
    ]

    @MainActor
    func testTheDebugMenuOpensAGalleryShowingEveryComponent() throws {
        continueAfterFailure = true
        let app = XCUIApplication.launchedFresh()
        let debug = app.menuBars.menuBarItems["Debug"]
        debug.click()
        debug.menuItems["Component Gallery"].click()
        let gallery = app.windows["Component Gallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 5))
        for id in Self.components {
            let element = gallery.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(element.waitForExistence(timeout: 2), "\(id) is missing")
        }
    }

    @MainActor
    func testTappingUndoInAnActivityRowPublishesAnUndoAskForThatEvent() throws {
        let app = XCUIApplication.launchedFresh()
        let debug = app.menuBars.menuBarItems["Debug"]
        debug.click()
        debug.menuItems["Component Gallery"].click()
        let gallery = app.windows["Component Gallery"]
        XCTAssertTrue(gallery.waitForExistence(timeout: 5))
        let rows = gallery.descendants(matching: .any)["gallery.activity-row"].firstMatch
        let undo = rows.buttons["Undo"].firstMatch
        XCTAssertTrue(undo.waitForExistence(timeout: 2))
        for _ in 0..<30 where !undo.isHittable {
            gallery.scrollViews.firstMatch.scroll(byDeltaX: 0, deltaY: -200)
        }
        app.activate()
        undo.click()
        let published = gallery.staticTexts["gallery.last-published"].firstMatch
        XCTAssertEqual(published.value as? String, "you.undo.asked evt_01M724TGJ0ZD9ADG44KY35BRFY")
    }
}
