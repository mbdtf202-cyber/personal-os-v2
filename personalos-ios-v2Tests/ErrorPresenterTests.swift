import XCTest
@testable import personalos_ios_v2

@MainActor
final class ErrorPresenterTests: XCTestCase {
    var presenter: ErrorPresenter!
    
    override func setUp() {
        presenter = ErrorPresenter.shared
    }
    
    override func tearDown() {
        presenter.currentError = nil
        presenter.toastMessage = nil
    }
    
    func testShowToast() {
        presenter.showToast("Test message")
        XCTAssertEqual(presenter.toastMessage, "Test message")
    }
    
    func testDismiss() {
        let error = AppError(title: "Test", message: "Test error", severity: .error)
        presenter.currentError = error
        
        presenter.dismiss()
        
        XCTAssertNil(presenter.currentError)
    }
    
    func testAppErrorFromNetworkError() {
        let error = NetworkError.timeout
        let appError = AppError.from(error, context: "Test")
        
        XCTAssertEqual(appError.title, "Test")
        XCTAssertTrue(appError.isRecoverable)
        XCTAssertEqual(appError.severity, .warning)
    }
}
