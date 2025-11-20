import XCTest
@testable import personalos_ios_v2

@MainActor
final class NetworkClientTests: XCTestCase {
    var client: NetworkClient!
    
    override func setUp() async throws {
        let config = NetworkConfig(
            timeout: 10,
            maxRetries: 2,
            retryDelay: 0.1,
            useExponentialBackoff: true,
            circuitBreakerThreshold: 3,
            circuitBreakerTimeout: 5
        )
        client = NetworkClient(config: config)
    }
    
    func testSuccessfulRequest() async throws {
        // This would require a mock URLSession
        // Skipping actual network call in unit test
    }
    
    func testRetryMechanism() async {
        // Test that failed requests are retried
        // Would require mock URLSession
    }
    
    func testCircuitBreaker() async {
        // Test that circuit breaker opens after threshold failures
        // Would require mock URLSession
    }
    
    func testOfflineCache() async {
        // Test that cached data is returned when network fails
        // Would require mock URLSession
    }
}
