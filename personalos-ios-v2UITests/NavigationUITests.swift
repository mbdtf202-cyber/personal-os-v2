import XCTest

final class NavigationUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testTabBarNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        let tabs = ["Home", "Growth", "Social", "Wealth", "News"]
        
        for tab in tabs {
            let tabButton = tabBar.buttons[tab]
            if tabButton.exists {
                tabButton.tap()
                XCTAssertTrue(tabButton.isSelected)
            }
        }
    }
    
    func testNavigationBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch
        
        tabBar.buttons["Home"].tap()
        sleep(1)
        
        tabBar.buttons["Social"].tap()
        sleep(1)
        
        tabBar.buttons["Wealth"].tap()
        sleep(1)
        
        tabBar.buttons["Home"].tap()
        XCTAssertTrue(tabBar.buttons["Home"].isSelected)
    }
}
