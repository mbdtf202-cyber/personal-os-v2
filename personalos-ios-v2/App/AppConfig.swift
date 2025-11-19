import Foundation

/// 全局配置
struct AppConfig {
    // MARK: - App Info
    static let appName = "PersonalOS"
    static let version = "1.0.0"
    static let buildNumber = "1"
    
    // MARK: - API Configuration
    struct API {
        static let baseURL = "https://api.personalos.com"
        static let timeout: TimeInterval = 30
        static let retryCount = 3
    }
    
    // MARK: - Feature Flags
    struct Features {
        static let enableGlobalSearch = true
        static let enableDarkMode = true
        static let enableNotifications = true
        static let enableCloudSync = false
        static let enableHealthKit = true
        static let enableGitHubSync = true
        static let enableRealTimePrices = true
    }
    
    // MARK: - UI Configuration
    struct UI {
        static let animationDuration: Double = 0.3
        static let cardCornerRadius: CGFloat = 16
        static let defaultPadding: CGFloat = 16
        static let maxCardWidth: CGFloat = 600
    }
    
    // MARK: - Data Configuration
    struct Data {
        static let maxCacheSize: Int = 100 * 1024 * 1024 // 100MB
        static let cacheExpiration: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        static let autoSaveInterval: TimeInterval = 30 // 30 seconds
    }
}
