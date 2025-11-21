import XCTest

final class SocialUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testSocialTabLoads() throws {
        let socialTab = app.tabBars.buttons["Social"]
        socialTab.tap()
        
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: 5))
    }
    
    func testNewPostButton() throws {
        let socialTab = app.tabBars.buttons["Social"]
        socialTab.tap()
        
        let addButton = app.buttons.matching(NSPredicate(format: "identifier CONTAINS 'plus'")).firstMatch
        if addButton.exists {
            addButton.tap()
            XCTAssertTrue(app.sheets.firstMatch.waitForExistence(timeout: 2))
        }
    }
}
