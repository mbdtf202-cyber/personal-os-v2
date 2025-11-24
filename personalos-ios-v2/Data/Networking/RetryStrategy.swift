import Foundation

/// ✅ P0 Task 17: Exponential backoff retry strategy
/// Requirement 15.3: Exponential backoff for failed requests
struct RetryStrategy {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    
    init(maxRetries: Int = 3, baseDelay: TimeInterval = 1.0, maxDelay: TimeInterval = 30.0) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
    }
    
    /// Calculate delay for retry attempt
    func delay(for attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.1) * exponentialDelay
        return min(exponentialDelay + jitter, maxDelay)
    }
    
    /// Check if should retry based on error
    func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        // Retry on network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut, .cannotConnectToHost, .networkConnectionLost, .notConnectedToInternet:
                return true
            default:
                return false
            }
        }
        
        // Retry on server errors (5xx)
        if let appError = error as? AppError,
           case .networkError(let statusCode, _) = appError,
           (500...599).contains(statusCode) {
            return true
        }
        
        return false
    }
}

/// Retry execution helper
extension RetryStrategy {
    /// Execute operation with retry logic
    func execute<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                guard shouldRetry(error: error, attempt: attempt) else {
                    throw error
                }
                
                let delayTime = delay(for: attempt)
                Logger.log("Retry attempt \(attempt + 1)/\(maxRetries) after \(delayTime)s", category: Logger.network)
                
                try await Task.sleep(nanoseconds: UInt64(delayTime * 1_000_000_000))
            }
        }
        
        throw lastError ?? AppError.unknown
    }
}
