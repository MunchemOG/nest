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
        "gallery.chat-bubble",
        "gallery.typing",
        "gallery.composer",
    ]

    @MainActor
    func testTheDebugMenuOpensAGalleryShowingEveryComponent() throws {
        continueAfterFailure = true
        let app = XCUIApplication()
        app.launch()
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
}
