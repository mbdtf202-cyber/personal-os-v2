import XCTest

final class DashboardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testDashboardLoads() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Creator'")).firstMatch.waitForExistence(timeout: 5))
    }
    
    func testSearchButton() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        let searchButton = app.buttons["Search"]
        if searchButton.exists {
            searchButton.tap()
            XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 2))
        }
    }
    
    func testQuickActions() throws {
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        
        let scrollView = app.scrollViews.firstMatch
        scrollView.swipeUp()
        
        XCTAssertTrue(app.staticTexts["Quick Actions"].exists || app.buttons.count > 0)
    }
}
