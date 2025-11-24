import Foundation

/// ✅ P0 Task 17: Request throttler for API rate limiting
/// Requirement 15.2: Client-side request throttling
@MainActor
class RequestThrottler {
    private var requestTimestamps: [String: [Date]] = [:]
    private let maxRequestsPerMinute: Int
    private let cleanupInterval: TimeInterval = 60.0
    
    init(maxRequestsPerMinute: Int = 60) {
        self.maxRequestsPerMinute = maxRequestsPerMinute
    }
    
    /// Check if request is allowed based on rate limit
    func canMakeRequest(for endpoint: String) -> Bool {
        let now = Date()
        let oneMinuteAgo = now.addingTimeInterval(-60)
        
        // Clean up old timestamps
        if var timestamps = requestTimestamps[endpoint] {
            timestamps.removeAll { $0 < oneMinuteAgo }
            requestTimestamps[endpoint] = timestamps
            
            // Check if under limit
            return timestamps.count < maxRequestsPerMinute
        }
        
        return true
    }
    
    /// Record a request
    func recordRequest(for endpoint: String) {
        let now = Date()
        if requestTimestamps[endpoint] == nil {
            requestTimestamps[endpoint] = []
        }
        requestTimestamps[endpoint]?.append(now)
    }
    
    /// Get time until next request is allowed
    func timeUntilNextRequest(for endpoint: String) -> TimeInterval {
        guard let timestamps = requestTimestamps[endpoint],
              timestamps.count >= maxRequestsPerMinute,
              let oldestTimestamp = timestamps.first else {
            return 0
        }
        
        let oneMinuteFromOldest = oldestTimestamp.addingTimeInterval(60)
        let now = Date()
        return max(0, oneMinuteFromOldest.timeIntervalSince(now))
    }
    
    /// Reset throttler for testing
    func reset() {
        requestTimestamps.removeAll()
    }
}
