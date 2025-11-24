import Foundation

/// ✅ P0 Task 17: Circuit breaker pattern for API resilience
/// Requirement 15.4: Circuit breaker to prevent cascading failures
@MainActor
class CircuitBreaker {
    enum State {
        case closed  // Normal operation
        case open    // Failing, reject requests
        case halfOpen // Testing if service recovered
    }
    
    private(set) var state: State = .closed
    private var failureCount: Int = 0
    private var lastFailureTime: Date?
    private var successCount: Int = 0
    
    let failureThreshold: Int
    let timeout: TimeInterval
    let halfOpenSuccessThreshold: Int
    
    init(failureThreshold: Int = 5, timeout: TimeInterval = 60.0, halfOpenSuccessThreshold: Int = 2) {
        self.failureThreshold = failureThreshold
        self.timeout = timeout
        self.halfOpenSuccessThreshold = halfOpenSuccessThreshold
    }
    
    /// Check if request is allowed
    func canAttempt() -> Bool {
        switch state {
        case .closed:
            return true
            
        case .open:
            // Check if timeout has passed
            if let lastFailure = lastFailureTime,
               Date().timeIntervalSince(lastFailure) >= timeout {
                Logger.log("Circuit breaker transitioning to half-open", category: Logger.network)
                state = .halfOpen
                successCount = 0
                return true
            }
            return false
            
        case .halfOpen:
            return true
        }
    }
    
    /// Record successful request
    func recordSuccess() {
        switch state {
        case .closed:
            failureCount = 0
            
        case .halfOpen:
            successCount += 1
            if successCount >= halfOpenSuccessThreshold {
                Logger.log("Circuit breaker closing after successful recovery", category: Logger.network)
                state = .closed
                failureCount = 0
                successCount = 0
            }
            
        case .open:
            break
        }
    }
    
    /// Record failed request
    func recordFailure() {
        lastFailureTime = Date()
        
        switch state {
        case .closed:
            failureCount += 1
            if failureCount >= failureThreshold {
                Logger.log("Circuit breaker opening after \(failureCount) failures", category: Logger.network)
                state = .open
            }
            
        case .halfOpen:
            Logger.log("Circuit breaker reopening after failure in half-open state", category: Logger.network)
            state = .open
            successCount = 0
            
        case .open:
            break
        }
    }
    
    /// Reset circuit breaker
    func reset() {
        state = .closed
        failureCount = 0
        successCount = 0
        lastFailureTime = nil
    }
    
    /// Execute operation with circuit breaker protection
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        guard canAttempt() else {
            throw AppError.serviceUnavailable("Circuit breaker is open")
        }
        
        do {
            let result = try await operation()
            recordSuccess()
            return result
        } catch {
            recordFailure()
            throw error
        }
    }
}
