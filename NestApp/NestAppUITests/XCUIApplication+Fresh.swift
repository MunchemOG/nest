import XCTest

extension XCUIApplication {
    /// Launches the app with no windows restored from earlier runs, so each test starts from the main window alone.
    static func launchedFresh() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments += ["-ApplePersistenceIgnoreState", "YES"]
        app.launch()
        return app
    }
}
