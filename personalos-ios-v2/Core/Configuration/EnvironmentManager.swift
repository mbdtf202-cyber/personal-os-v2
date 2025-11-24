import Foundation

enum AppEnvironment: String, Codable {
    case development
    case staging
    case production
    
    static var current: AppEnvironment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dev-api.personalos.com"
        case .staging:
            return "https://staging-api.personalos.com"
        case .production:
            return "https://api.personalos.com"
        }
    }
    
    var remoteConfigURL: String {
        return "\(baseURL)/config/features"
    }
    
    var shouldSeedMockData: Bool {
        return self != .production
    }
    
    var isDebugMode: Bool {
        return self == .development
    }
    
    var logLevel: LogLevel {
        switch self {
        case .development:
            return .debug
        case .staging:
            return .info
        case .production:
            return .warning
        }
    }
}

enum LogLevel: Int {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
}

final class EnvironmentManager {
    static let shared = EnvironmentManager()
    
    let environment: AppEnvironment
    
    // ✅ P0 Fix: Expose current environment for checks
    var currentEnvironment: AppEnvironment {
        return environment
    }
    
    // ✅ P0 Fix: Mock environment for testing
    enum MockEnvironment {
        case mock
    }
    
    private init() {
        self.environment = AppEnvironment.current
    }
    
    func baseURL(for service: String) -> URL {
        let urlString: String
        switch service {
        case "news":
            urlString = "\(environment.baseURL)/news"
        case "github":
            urlString = "\(environment.baseURL)/github"
        case "stock":
            urlString = "\(environment.baseURL)/stock"
        default:
            urlString = environment.baseURL
        }
        return URL(string: urlString)!
    }
    
    func shouldSeedMockData() -> Bool {
        return environment.shouldSeedMockData
    }
    
    func isDebugMode() -> Bool {
        return environment.isDebugMode
    }
}
