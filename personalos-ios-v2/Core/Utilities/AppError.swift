import Foundation

/// Error severity levels
enum ErrorSeverity {
    case warning
    case error
    case critical
}

/// Comprehensive application error types
enum AppError: Error, Identifiable {
    // Network errors
    case network(NetworkError, retryable: Bool)
    case networkError(statusCode: Int, message: String)
    
    // Database errors
    case database(DatabaseError, recoverable: Bool)
    
    // Validation errors
    case validation(ValidationError)
    
    // Security errors
    case security(SecurityError)
    
    // Configuration errors
    case configuration(ConfigurationError)
    
    // Business logic errors
    case business(BusinessError)
    
    // ✅ P0 Fix: Additional error types
    case rateLimitExceeded
    case serviceUnavailable(String)
    case unknown
    
    var id: UUID { UUID() }
    
    /// User-friendly error message
    var userMessage: String {
        switch self {
        case .network(let error, _):
            return error.userMessage
        case .networkError(let statusCode, let message):
            return "Network error (\(statusCode)): \(message)"
        case .database(let error, _):
            return error.userMessage
        case .validation(let error):
            return error.userMessage
        case .security(let error):
            return error.userMessage
        case .configuration(let error):
            return error.userMessage
        case .business(let error):
            return error.userMessage
        case .rateLimitExceeded:
            return "Too many requests. Please wait a moment."
        case .serviceUnavailable(let message):
            return "Service unavailable: \(message)"
        case .unknown:
            return "An unknown error occurred"
        }
    }
    
    /// Detailed debug description
    var debugDescription: String {
        switch self {
        case .network(let error, let retryable):
            return "Network Error (retryable: \(retryable)): \(error)"
        case .networkError(let statusCode, let message):
            return "Network Error (\(statusCode)): \(message)"
        case .database(let error, let recoverable):
            return "Database Error (recoverable: \(recoverable)): \(error)"
        case .validation(let error):
            return "Validation Error: \(error)"
        case .security(let error):
            return "Security Error: \(error)"
        case .configuration(let error):
            return "Configuration Error: \(error)"
        case .business(let error):
            return "Business Error: \(error)"
        case .rateLimitExceeded:
            return "Rate Limit Exceeded"
        case .serviceUnavailable(let message):
            return "Service Unavailable: \(message)"
        case .unknown:
            return "Unknown Error"
        }
    }
    
    /// Whether the error can be retried
    var canRetry: Bool {
        switch self {
        case .network(_, let retryable):
            return retryable
        case .networkError(let statusCode, _):
            return (500...599).contains(statusCode)
        case .database(_, let recoverable):
            return recoverable
        case .validation:
            return false
        case .security:
            return false
        case .configuration:
            return false
        case .business(let error):
            return error.canRetry
        case .rateLimitExceeded:
            return true
        case .serviceUnavailable:
            return true
        case .unknown:
            return false
        }
    }
    
    /// Error severity
    var severity: ErrorSeverity {
        switch self {
        case .network(let error, _):
            return error.severity
        case .networkError(let statusCode, _):
            return (500...599).contains(statusCode) ? .error : .warning
        case .database(let error, _):
            return error.severity
        case .validation:
            return .warning
        case .security:
            return .critical
        case .configuration:
            return .error
        case .business(let error):
            return error.severity
        case .rateLimitExceeded:
            return .warning
        case .serviceUnavailable:
            return .error
        case .unknown:
            return .error
        }
    }
}

/// Network-specific errors
enum NetworkError: Error {
    case noConnection
    case timeout
    case serverError(Int)
    case rateLimited
    case invalidResponse
    case circuitBreakerOpen
    case unauthorized
    case forbidden
    
    var userMessage: String {
        switch self {
        case .noConnection:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code):
            return "Server error (\(code)). Please try again later."
        case .rateLimited:
            return "Too many requests. Please wait a moment."
        case .invalidResponse:
            return "Invalid server response. Please try again."
        case .circuitBreakerOpen:
            return "Service temporarily unavailable. Please try again later."
        case .unauthorized:
            return "Authentication required. Please sign in."
        case .forbidden:
            return "Access denied. You don't have permission."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .noConnection, .timeout, .rateLimited:
            return .warning
        case .serverError, .invalidResponse, .circuitBreakerOpen:
            return .error
        case .unauthorized, .forbidden:
            return .error
        }
    }
}

/// Database-specific errors
enum DatabaseError: Error {
    case migrationFailed
    case corruptedData
    case constraintViolation
    case concurrencyConflict
    case saveFailed
    case fetchFailed
    case deleteFailed
    
    var userMessage: String {
        switch self {
        case .migrationFailed:
            return "Database upgrade failed. Please restart the app."
        case .corruptedData:
            return "Data corruption detected. Please contact support."
        case .constraintViolation:
            return "Invalid data. Please check your input."
        case .concurrencyConflict:
            return "Data conflict. Please try again."
        case .saveFailed:
            return "Failed to save data. Please try again."
        case .fetchFailed:
            return "Failed to load data. Please try again."
        case .deleteFailed:
            return "Failed to delete data. Please try again."
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .migrationFailed, .corruptedData:
            return .critical
        case .constraintViolation, .concurrencyConflict:
            return .warning
        case .saveFailed, .fetchFailed, .deleteFailed:
            return .error
        }
    }
}

/// Validation-specific errors
enum ValidationError: Error {
    case insufficientQuantity(symbol: String, available: Decimal, requested: Decimal)
    case negativePosition(symbol: String)
    case invalidPrice
    case invalidDate
    case invalidInput(field: String, reason: String)
    case missingRequiredField(field: String)
    
    var userMessage: String {
        switch self {
        case .insufficientQuantity(let symbol, let available, let requested):
            return "Insufficient quantity for \(symbol). Available: \(available), Requested: \(requested)"
        case .negativePosition(let symbol):
            return "Cannot sell more than you own for \(symbol)"
        case .invalidPrice:
            return "Invalid price. Please enter a valid number."
        case .invalidDate:
            return "Invalid date. Please select a valid date."
        case .invalidInput(let field, let reason):
            return "Invalid \(field): \(reason)"
        case .missingRequiredField(let field):
            return "\(field) is required"
        }
    }
}

/// Security-specific errors
enum SecurityError: Error {
    case jailbroken
    case certificateValidationFailed
    case keychainAccessDenied
    case encryptionFailed
    case decryptionFailed
    case unauthorizedAccess
    
    var userMessage: String {
        switch self {
        case .jailbroken:
            return "Security risk detected. This app cannot run on jailbroken devices."
        case .certificateValidationFailed:
            return "Secure connection failed. Please check your network."
        case .keychainAccessDenied:
            return "Cannot access secure storage. Please check permissions."
        case .encryptionFailed:
            return "Failed to encrypt data. Please try again."
        case .decryptionFailed:
            return "Failed to decrypt data. Data may be corrupted."
        case .unauthorizedAccess:
            return "Unauthorized access attempt detected."
        }
    }
}

/// Configuration-specific errors
enum ConfigurationError: Error {
    case missingAPIKey(service: String)
    case invalidConfiguration(reason: String)
    case featureDisabled(feature: String)
    case environmentMismatch
    
    var userMessage: String {
        switch self {
        case .missingAPIKey(let service):
            return "Configuration error: Missing API key for \(service)"
        case .invalidConfiguration(let reason):
            return "Configuration error: \(reason)"
        case .featureDisabled(let feature):
            return "\(feature) is currently disabled"
        case .environmentMismatch:
            return "Environment configuration mismatch"
        }
    }
}

/// Business logic errors
enum BusinessError: Error {
    case operationNotAllowed(reason: String)
    case resourceNotFound(resource: String)
    case duplicateEntry(resource: String)
    case quotaExceeded(resource: String, limit: Int)
    case invalidState(reason: String)
    
    var userMessage: String {
        switch self {
        case .operationNotAllowed(let reason):
            return "Operation not allowed: \(reason)"
        case .resourceNotFound(let resource):
            return "\(resource) not found"
        case .duplicateEntry(let resource):
            return "\(resource) already exists"
        case .quotaExceeded(let resource, let limit):
            return "\(resource) limit exceeded (max: \(limit))"
        case .invalidState(let reason):
            return "Invalid state: \(reason)"
        }
    }
    
    var canRetry: Bool {
        switch self {
        case .operationNotAllowed, .duplicateEntry, .invalidState:
            return false
        case .resourceNotFound, .quotaExceeded:
            return true
        }
    }
    
    var severity: ErrorSeverity {
        switch self {
        case .operationNotAllowed, .invalidState:
            return .warning
        case .resourceNotFound, .duplicateEntry, .quotaExceeded:
            return .error
        }
    }
}

/// Error recovery strategy protocol
protocol ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool
    func recover(from error: AppError) async throws
}

/// Network error recovery strategy
final class NetworkErrorRecovery: ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool {
        guard case .network(_, let retryable) = error else { return false }
        return retryable
    }
    
    func recover(from error: AppError) async throws {
        guard case .network(let networkError, _) = error else {
            throw AppError.business(.operationNotAllowed(reason: "Not a network error"))
        }
        
        // Implement exponential backoff
        switch networkError {
        case .timeout, .serverError, .circuitBreakerOpen:
            // Wait before retry
            try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
            Logger.log("Retrying after network error", category: Logger.general)
            
        case .rateLimited:
            // Wait longer for rate limit
            try await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds
            Logger.log("Retrying after rate limit", category: Logger.general)
            
        default:
            throw AppError.business(.operationNotAllowed(reason: "Cannot recover from this network error"))
        }
    }
}

/// Database error recovery strategy
final class DatabaseErrorRecovery: ErrorRecoveryStrategy {
    func canRecover(from error: AppError) -> Bool {
        guard case .database(_, let recoverable) = error else { return false }
        return recoverable
    }
    
    func recover(from error: AppError) async throws {
        guard case .database(let dbError, _) = error else {
            throw AppError.business(.operationNotAllowed(reason: "Not a database error"))
        }
        
        switch dbError {
        case .concurrencyConflict:
            // Retry after brief delay
            try await Task.sleep(nanoseconds: 500_000_000)  // 0.5 seconds
            Logger.log("Retrying after concurrency conflict", category: Logger.general)
            
        case .saveFailed, .fetchFailed, .deleteFailed:
            // Retry immediately
            Logger.log("Retrying database operation", category: Logger.general)
            
        default:
            throw AppError.business(.operationNotAllowed(reason: "Cannot recover from this database error"))
        }
    }
}
