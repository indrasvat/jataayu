import XCTest

final class JoolsUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testRunningSessionScreenShowsRecoveryChrome() throws {
        let app = makeApp(scenario: "running-session")
        app.launch()

        openSessionsTab(in: app)

        openSession(named: "UI Test Running Session", in: app)

        XCTAssertTrue(app.staticTexts["Review and approve the plan"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Provide the summary to the user"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.scrollViews["chat.scroll"].exists || app.otherElements["chat.scroll"].exists)
        XCTAssertTrue(app.textFields["chat.input"].exists || app.textViews["chat.input"].exists)
        XCTAssertTrue(app.buttons["chat.send"].exists)
        XCTAssertTrue(app.buttons["chat.refresh"].exists)
        XCTAssertTrue(staticText(containing: "Last updated", in: app).waitForExistence(timeout: 5))
    }

    @MainActor
    func testStaleSessionShowsRetryAction() throws {
        let app = makeApp(
            scenario: "stale-session",
            syncState: "stale"
        )
        app.launch()

        openSessionsTab(in: app)

        openSession(named: "UI Test Stale Session", in: app)

        XCTAssertTrue(staticText(containing: "Showing the last synced timeline", in: app).waitForExistence(timeout: 5))
        XCTAssertTrue(
            app.buttons["Tap to retry"].exists ||
            app.buttons["chat.retry"].exists ||
            app.staticTexts["Tap to retry"].exists
        )
    }

    @MainActor
    func testSessionScreenSurvivesBackgroundForeground() throws {
        let app = makeApp(scenario: "running-session")
        app.launch()

        openSessionsTab(in: app)
        openSession(named: "UI Test Running Session", in: app)

        XCTAssertTrue(app.staticTexts["Provide the summary to the user"].waitForExistence(timeout: 5))
        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertTrue(app.staticTexts["Provide the summary to the user"].exists)
        XCTAssertTrue(app.buttons["chat.refresh"].exists)
    }

    private func makeApp(scenario: String, syncState: String? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchEnvironment["JOOLS_UI_TEST_MODE"] = "1"
        app.launchEnvironment["JOOLS_UI_TEST_SCENARIO"] = scenario
        if let syncState {
            app.launchEnvironment["JOOLS_UI_TEST_SYNC_STATE"] = syncState
        }
        return app
    }

    private func openSessionsTab(in app: XCUIApplication) {
        let tabButton = app.tabBars.buttons["tab.sessions"].firstMatch
        if tabButton.waitForExistence(timeout: 5) {
            tabButton.tap()
            return
        }

        let titledTabButton = app.tabBars.buttons["Sessions"].firstMatch
        XCTAssertTrue(titledTabButton.waitForExistence(timeout: 5))
        titledTabButton.tap()
    }

    private func openSession(named title: String, in app: XCUIApplication) {
        let titleText = app.staticTexts[title].firstMatch
        XCTAssertTrue(titleText.waitForExistence(timeout: 5))

        let containingCell = app.cells.containing(.staticText, identifier: title).firstMatch
        if containingCell.exists {
            containingCell.tap()
            return
        }

        titleText.tap()
    }

    private func staticText(containing substring: String, in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", substring)).firstMatch
    }
}
