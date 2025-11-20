import XCTest

final class personalos_ios_v2UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests
    
    @MainActor
    func testAppLaunches() throws {
        XCTAssertTrue(app.state == .runningForeground)
    }
    
    // MARK: - Tab Navigation Tests
    
    @MainActor
    func testTabBarExists() throws {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.exists)
    }
    
    @MainActor
    func testNavigationBetweenTabs() throws {
        let tabBar = app.tabBars.firstMatch
        
        // Test Home tab
        let homeTab = tabBar.buttons["Home"]
        if homeTab.exists {
            homeTab.tap()
            XCTAssertTrue(homeTab.isSelected)
        }
        
        // Test Projects tab
        let projectsTab = tabBar.buttons["Projects"]
        if projectsTab.exists {
            projectsTab.tap()
            XCTAssertTrue(projectsTab.isSelected)
        }
        
        // Test Social tab
        let socialTab = tabBar.buttons["Social"]
        if socialTab.exists {
            socialTab.tap()
            XCTAssertTrue(socialTab.isSelected)
        }
        
        // Test News tab
        let newsTab = tabBar.buttons["News"]
        if newsTab.exists {
            newsTab.tap()
            XCTAssertTrue(newsTab.isSelected)
        }
        
        // Test Apps tab
        let appsTab = tabBar.buttons["Apps"]
        if appsTab.exists {
            appsTab.tap()
            XCTAssertTrue(appsTab.isSelected)
        }
    }
    
    // MARK: - Dashboard Tests
    
    @MainActor
    func testDashboardSearchButton() throws {
        let searchButton = app.buttons.matching(identifier: "magnifyingglass").firstMatch
        if searchButton.exists {
            searchButton.tap()
            // Global search should appear
            XCTAssertTrue(app.otherElements["GlobalSearchView"].exists || app.textFields.count > 0)
        }
    }
    
    // MARK: - Trading Module Tests
    
    @MainActor
    func testTradingModuleAccess() throws {
        // Navigate to Apps tab
        let appsTab = app.tabBars.firstMatch.buttons["Apps"]
        if appsTab.exists {
            appsTab.tap()
            
            // Find and tap Trading module
            let tradingButton = app.buttons["Trading"]
            if tradingButton.exists {
                tradingButton.tap()
                
                // Verify Trading Journal screen appears
                XCTAssertTrue(app.navigationBars["Trading Journal"].exists)
            }
        }
    }
    
    @MainActor
    func testAddTradeButton() throws {
        // Navigate to Trading module first
        let appsTab = app.tabBars.firstMatch.buttons["Apps"]
        if appsTab.exists {
            appsTab.tap()
            
            let tradingButton = app.buttons["Trading"]
            if tradingButton.exists {
                tradingButton.tap()
                
                // Find and tap the add button
                let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus'")).firstMatch
                if addButton.exists {
                    addButton.tap()
                    
                    // Verify trade form appears
                    XCTAssertTrue(app.navigationBars["Log Trade"].exists)
                }
            }
        }
    }
    
    // MARK: - Performance Tests
    
    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
    
    @MainActor
    func testScrollPerformance() throws {
        let scrollView = app.scrollViews.firstMatch
        
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric]) {
            if scrollView.exists {
                scrollView.swipeUp()
                scrollView.swipeDown()
            }
        }
    }
}
