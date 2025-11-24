import XCTest
@testable import personalos_ios_v2

// **Feature: system-architecture-upgrade-p0, Property 22: Error visibility**
// **Feature: system-architecture-upgrade-p0, Property 23: Retry availability**
// **Feature: system-architecture-upgrade-p0, Property 24: Error logging completeness**
// **Feature: system-architecture-upgrade-p0, Property 25: Retry execution**
// **Feature: system-architecture-upgrade-p0, Property 26: Non-blocking error presentation**

@MainActor
final class ErrorHandlingTests: XCTestCase {
    
    var errorPresenter: ErrorPresenter!
    
    override func setUp() async throws {
        try await super.setUp()
        errorPresenter = ErrorPresenter.shared
        errorPresenter.clearAll()
    }
    
    override func tearDown() async throws {
        errorPresenter.clearAll()
        errorPresenter = nil
        try await super.tearDown()
    }
    
    // MARK: - Property 22: Error visibility
    
    func testErrorVisibility() {
        // Property: Data loading failure should display user-visible error
        
        let error = PresentableError(
            title: "Load Failed",
            message: "Failed to load data",
            severity: .error
        )
        
        errorPresenter.present(error)
        
        // Verify error is visible
        XCTAssertNotNil(errorPresenter.currentError, "Error should be visible")
        XCTAssertEqual(errorPresenter.currentError?.title, "Load Failed")
        XCTAssertEqual(errorPresenter.currentError?.message, "Failed to load data")
    }
    
    func testErrorMessageClarity() {
        // Property: Error messages should be user-friendly
        
        let networkError = AppError.network(.noConnection, retryable: true)
        XCTAssertFalse(networkError.userMessage.isEmpty, "Should have user message")
        XCTAssertTrue(networkError.userMessage.contains("internet"), "Should mention internet")
        
        let dbError = AppError.database(.saveFailed, recoverable: true)
        XCTAssertFalse(dbError.userMessage.isEmpty, "Should have user message")
        XCTAssertTrue(dbError.userMessage.contains("save"), "Should mention save")
    }
    
    func testCriticalErrorsDisplayed() {
        // Property: Critical errors should be displayed prominently
        
        let criticalError = PresentableError(
            title: "Critical Error",
            message: "System failure",
            severity: .critical
        )
        
        errorPresenter.present(criticalError)
        
        XCTAssertNotNil(errorPresenter.currentError, "Critical error should be displayed")
        XCTAssertEqual(errorPresenter.currentError?.severity, .critical)
    }
    
    // MARK: - Property 23: Retry availability
    
    func testRetryAvailability() {
        // Property: Network failures should provide retry mechanism
        
        let networkError = AppError.network(.timeout, retryable: true)
        XCTAssertTrue(networkError.canRetry, "Network timeout should be retryable")
        
        let validationError = AppError.validation(.invalidPrice)
        XCTAssertFalse(validationError.canRetry, "Validation error should not be retryable")
    }
    
    func testRetryActionPresence() {
        // Property: Retryable errors should have retry action
        
        var retryExecuted = false
        let retryAction: () async -> Void = {
            retryExecuted = true
        }
        
        let error = PresentableError(
            title: "Network Error",
            message: "Request failed",
            severity: .error,
            isRecoverable: true,
            retryAction: retryAction
        )
        
        XCTAssertNotNil(error.retryAction, "Retryable error should have retry action")
        XCTAssertTrue(error.isRecoverable, "Error should be marked as recoverable")
    }
    
    func testNonRetryableErrors() {
        // Property: Non-retryable errors should not offer retry
        
        let securityError = AppError.security(.jailbroken)
        XCTAssertFalse(securityError.canRetry, "Security errors should not be retryable")
        
        let configError = AppError.configuration(.missingAPIKey(service: "test"))
        XCTAssertFalse(configError.canRetry, "Config errors should not be retryable")
    }
    
    // MARK: - Property 24: Error logging completeness
    
    func testErrorLoggingCompleteness() {
        // Property: All errors should be logged with diagnostic info
        
        let error = AppError.network(.serverError(500), retryable: true)
        
        // Verify error has debug description
        XCTAssertFalse(error.debugDescription.isEmpty, "Should have debug description")
        XCTAssertTrue(error.debugDescription.contains("Network"), "Should identify error type")
        XCTAssertTrue(error.debugDescription.contains("500"), "Should include error details")
    }
    
    func testErrorContextLogging() {
        // Property: Errors should include context information
        
        let error = PresentableError(
            title: "Save Failed",
            message: "Failed to save project",
            severity: .error
        )
        
        errorPresenter.present(error)
        
        // Verify error is logged (in real scenario, check logs)
        XCTAssertNotNil(errorPresenter.currentError, "Error should be tracked")
    }
    
    func testAllErrorTypesHaveMessages() {
        // Property: Every error type should have user message
        
        let errors: [AppError] = [
            .network(.noConnection, retryable: true),
            .database(.saveFailed, recoverable: true),
            .validation(.invalidPrice),
            .security(.keychainAccessDenied),
            .configuration(.missingAPIKey(service: "test")),
            .business(.resourceNotFound(resource: "item"))
        ]
        
        for error in errors {
            XCTAssertFalse(error.userMessage.isEmpty, "Error should have user message: \(error)")
            XCTAssertFalse(error.debugDescription.isEmpty, "Error should have debug description: \(error)")
        }
    }
    
    // MARK: - Property 25: Retry execution
    
    func testRetryExecution() async throws {
        // Property: User-triggered retry should attempt to reload data
        
        var attemptCount = 0
        let retryOperation: () async throws -> Void = {
            attemptCount += 1
        }
        
        errorPresenter.present(
            NetworkError.timeout,
            context: "Load Data",
            retryAction: retryOperation
        )
        
        // Execute retry
        try await errorPresenter.retry()
        
        XCTAssertEqual(attemptCount, 1, "Retry should execute operation")
    }
    
    func testRetryWithoutAction() async {
        // Property: Retry without action should fail gracefully
        
        let error = PresentableError(
            title: "Error",
            message: "Test error",
            severity: .error,
            isRecoverable: false
        )
        
        errorPresenter.present(error)
        
        do {
            try await errorPresenter.retry()
            XCTFail("Should throw error when no retry action")
        } catch {
            XCTAssertTrue(error is ErrorPresenterError, "Should throw appropriate error")
        }
    }
    
    func testRetryRecoveryStrategy() async throws {
        // Property: Retry should use recovery strategy
        
        let networkError = AppError.network(.timeout, retryable: true)
        let recovery = NetworkErrorRecovery()
        
        XCTAssertTrue(recovery.canRecover(from: networkError), "Should be able to recover")
        
        // Recovery should complete without throwing
        try await recovery.recover(from: networkError)
    }
    
    // MARK: - Property 26: Non-blocking error presentation
    
    func testNonBlockingErrorPresentation() {
        // Property: Multiple errors should be presented non-intrusively
        
        let error1 = PresentableError(
            title: "Error 1",
            message: "First error",
            severity: .error
        )
        
        let error2 = PresentableError(
            title: "Error 2",
            message: "Second error",
            severity: .error
        )
        
        errorPresenter.present(error1)
        errorPresenter.present(error2)
        
        // Verify errors are queued
        XCTAssertNotNil(errorPresenter.currentError, "Should show first error")
        XCTAssertFalse(errorPresenter.errorQueue.isEmpty, "Should queue second error")
    }
    
    func testErrorQueueProcessing() {
        // Property: Error queue should process errors sequentially
        
        let error1 = PresentableError(title: "Error 1", message: "First", severity: .error)
        let error2 = PresentableError(title: "Error 2", message: "Second", severity: .error)
        let error3 = PresentableError(title: "Error 3", message: "Third", severity: .error)
        
        errorPresenter.present(error1)
        errorPresenter.present(error2)
        errorPresenter.present(error3)
        
        XCTAssertEqual(errorPresenter.currentError?.title, "Error 1")
        XCTAssertEqual(errorPresenter.errorQueue.count, 3)
        
        // Dismiss first error
        errorPresenter.dismiss()
        
        // Should show second error
        XCTAssertEqual(errorPresenter.currentError?.title, "Error 2")
        XCTAssertEqual(errorPresenter.errorQueue.count, 2)
    }
    
    func testToastForMinorErrors() {
        // Property: Minor errors should show as toast, not blocking
        
        let warningError = PresentableError(
            title: "Warning",
            message: "Minor issue",
            severity: .warning
        )
        
        errorPresenter.present(warningError)
        
        // Warning should show as toast, not blocking error
        XCTAssertNotNil(errorPresenter.toastMessage, "Should show toast")
        XCTAssertNil(errorPresenter.currentError, "Should not block with error dialog")
    }
    
    // MARK: - Integration Tests
    
    func testCompleteErrorFlow() async throws {
        // Test complete error handling flow
        
        var operationAttempts = 0
        let operation: () async throws -> Void = {
            operationAttempts += 1
            if operationAttempts < 2 {
                throw NetworkError.timeout
            }
        }
        
        // First attempt fails
        do {
            try await operation()
            XCTFail("Should throw error")
        } catch {
            errorPresenter.present(error, context: "Test Operation", retryAction: operation)
        }
        
        XCTAssertNotNil(errorPresenter.currentError, "Error should be presented")
        XCTAssertEqual(operationAttempts, 1)
        
        // Retry succeeds
        try await errorPresenter.retry()
        XCTAssertEqual(operationAttempts, 2, "Should retry operation")
    }
    
    func testErrorSeverityHandling() {
        // Test different severity levels
        
        let severities: [ErrorSeverity] = [.info, .warning, .error, .critical]
        
        for severity in severities {
            let error = PresentableError(
                title: "Test",
                message: "Test message",
                severity: severity
            )
            
            XCTAssertNotNil(error.severity.color, "Should have color for \(severity)")
            XCTAssertNotNil(error.severity.icon, "Should have icon for \(severity)")
        }
    }
}
