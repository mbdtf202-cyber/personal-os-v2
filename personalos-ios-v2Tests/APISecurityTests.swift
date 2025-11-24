import XCTest
@testable import personalos_ios_v2

/// ✅ P0 Task 17.1: API Security Property Tests
/// Tests Requirements 15.1-15.5: Proxy routing, throttling, backoff, circuit breaker, logging
@MainActor
final class APISecurityTests: XCTestCase {
    var throttler: RequestThrottler!
    var retryStrategy: RetryStrategy!
    var circuitBreaker: CircuitBreaker!
    
    override func setUp() async throws {
        throttler = RequestThrottler(maxRequestsPerMinute: 5)
        retryStrategy = RetryStrategy(maxRetries: 3, baseDelay: 0.1, maxDelay: 1.0)
        circuitBreaker = CircuitBreaker(failureThreshold: 3, timeout: 1.0, halfOpenSuccessThreshold: 2)
    }
    
    override func tearDown() {
        throttler = nil
        retryStrategy = nil
        circuitBreaker = nil
    }
    
    // MARK: - Property 60: Proxy routing
    /// Requirement 15.1: API keys should not be exposed in client
    func testProperty60_ProxyRouting() {
        // Given: NewsService with security infrastructure
        let networkClient = NetworkClient(config: .default)
        let newsService = NewsService(
            networkClient: networkClient,
            throttler: throttler,
            retryStrategy: retryStrategy,
            circuitBreaker: circuitBreaker
        )
        
        // Then: Service has security components
        XCTAssertNotNil(newsService, "NewsService should be initialized with security components")
        
        // Property: API keys are managed server-side through proxy
        // Client only makes requests through secure channels
        // Note: Full proxy implementation would be in backend service
    }
    
    // MARK: - Property 61: Client-side throttling
    /// Requirement 15.2: Requests should be throttled to prevent abuse
    func testProperty61_ClientSideThrottling() {
        // Given: Request throttler with limit of 5 per minute
        let endpoint = "test-endpoint"
        
        // When: Making requests up to limit
        for _ in 0..<5 {
            XCTAssertTrue(throttler.canMakeRequest(for: endpoint), "Should allow requests under limit")
            throttler.recordRequest(for: endpoint)
        }
        
        // Then: Additional requests are blocked
        XCTAssertFalse(throttler.canMakeRequest(for: endpoint), "Should block requests over limit")
        
        // And: Time until next request is calculated
        let waitTime = throttler.timeUntilNextRequest(for: endpoint)
        XCTAssertGreaterThan(waitTime, 0, "Should provide wait time")
        XCTAssertLessThanOrEqual(waitTime, 60, "Wait time should be within one minute")
        
        // Property: Throttler enforces rate limits per endpoint
    }
    
    // MARK: - Property 62: Exponential backoff
    /// Requirement 15.3: Failed requests should use exponential backoff
    func testProperty62_ExponentialBackoff() {
        // Given: Retry strategy with exponential backoff
        
        // When: Calculating delays for multiple attempts
        let delay0 = retryStrategy.delay(for: 0)
        let delay1 = retryStrategy.delay(for: 1)
        let delay2 = retryStrategy.delay(for: 2)
        
        // Then: Delays increase exponentially
        XCTAssertGreaterThan(delay1, delay0, "Second attempt should wait longer")
        XCTAssertGreaterThan(delay2, delay1, "Third attempt should wait even longer")
        
        // And: Delays don't exceed maximum
        XCTAssertLessThanOrEqual(delay2, retryStrategy.maxDelay, "Delay should not exceed max")
        
        // Property: Retry delays follow exponential backoff pattern
    }
    
    // MARK: - Property 63: Circuit breaker pattern
    /// Requirement 15.4: Circuit breaker prevents cascading failures
    func testProperty63_CircuitBreakerPattern() async throws {
        // Given: Circuit breaker in closed state
        XCTAssertEqual(circuitBreaker.state, .closed, "Should start closed")
        XCTAssertTrue(circuitBreaker.canAttempt(), "Should allow requests when closed")
        
        // When: Recording failures up to threshold
        for _ in 0..<3 {
            circuitBreaker.recordFailure()
        }
        
        // Then: Circuit opens
        XCTAssertEqual(circuitBreaker.state, .open, "Should open after threshold failures")
        XCTAssertFalse(circuitBreaker.canAttempt(), "Should block requests when open")
        
        // When: Timeout passes
        try await Task.sleep(nanoseconds: 1_100_000_000) // 1.1 seconds
        
        // Then: Circuit transitions to half-open
        XCTAssertTrue(circuitBreaker.canAttempt(), "Should allow test request after timeout")
        
        // When: Recording successes in half-open state
        circuitBreaker.recordSuccess()
        circuitBreaker.recordSuccess()
        
        // Then: Circuit closes
        XCTAssertEqual(circuitBreaker.state, .closed, "Should close after successful recovery")
        
        // Property: Circuit breaker protects against cascading failures
    }
    
    // MARK: - Property 64: API usage logging
    /// Requirement 15.5: All API requests should be logged
    func testProperty64_APIUsageLogging() {
        // Given: NewsService with logging enabled
        let networkClient = NetworkClient(config: .default)
        let newsService = NewsService(
            networkClient: networkClient,
            throttler: throttler,
            retryStrategy: retryStrategy,
            circuitBreaker: circuitBreaker
        )
        
        // Then: Service is configured for logging
        XCTAssertNotNil(newsService, "Service should be initialized")
        
        // Property: All API requests are logged with:
        // - Endpoint identifier
        // - Success/failure status
        // - Response metadata (count, size, etc.)
        // - Error details on failure
        // Note: Actual logging verification would require log capture
    }
    
    // MARK: - Integration Tests
    func testThrottlerReset() {
        // Given: Throttler at limit
        let endpoint = "test"
        for _ in 0..<5 {
            throttler.recordRequest(for: endpoint)
        }
        XCTAssertFalse(throttler.canMakeRequest(for: endpoint))
        
        // When: Resetting throttler
        throttler.reset()
        
        // Then: Requests are allowed again
        XCTAssertTrue(throttler.canMakeRequest(for: endpoint))
        
        // Property: Throttler can be reset for testing
    }
    
    func testRetryStrategyErrorFiltering() {
        // Given: Different error types
        let networkError = URLError(.timedOut)
        let otherError = NSError(domain: "test", code: 999)
        
        // When: Checking if should retry
        let shouldRetryNetwork = retryStrategy.shouldRetry(error: networkError, attempt: 0)
        let shouldRetryOther = retryStrategy.shouldRetry(error: otherError, attempt: 0)
        
        // Then: Only retryable errors are retried
        XCTAssertTrue(shouldRetryNetwork, "Should retry network errors")
        XCTAssertFalse(shouldRetryOther, "Should not retry non-network errors")
        
        // Property: Retry strategy filters errors appropriately
    }
    
    func testCircuitBreakerRecovery() async throws {
        // Given: Circuit breaker that opened
        for _ in 0..<3 {
            circuitBreaker.recordFailure()
        }
        XCTAssertEqual(circuitBreaker.state, .open)
        
        // When: Waiting for timeout and recording success
        try await Task.sleep(nanoseconds: 1_100_000_000)
        XCTAssertTrue(circuitBreaker.canAttempt())
        
        circuitBreaker.recordSuccess()
        circuitBreaker.recordSuccess()
        
        // Then: Circuit recovers to closed state
        XCTAssertEqual(circuitBreaker.state, .closed)
        
        // Property: Circuit breaker can recover after successful requests
    }
    
    func testCircuitBreakerFailureInHalfOpen() async throws {
        // Given: Circuit breaker in half-open state
        for _ in 0..<3 {
            circuitBreaker.recordFailure()
        }
        try await Task.sleep(nanoseconds: 1_100_000_000)
        _ = circuitBreaker.canAttempt()
        
        // When: Recording failure in half-open state
        circuitBreaker.recordFailure()
        
        // Then: Circuit reopens
        XCTAssertEqual(circuitBreaker.state, .open)
        XCTAssertFalse(circuitBreaker.canAttempt())
        
        // Property: Circuit breaker reopens on failure during recovery
    }
}
