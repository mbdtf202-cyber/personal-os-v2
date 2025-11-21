import Foundation

/// API Configuration
/// IMPORTANT: Never commit real API keys to version control
/// All API keys are securely stored in Keychain
enum APIConfig {
    // 🔒 P1 Fix: 直接从 Keychain 读取，移除 UserDefaults 安全剧场
    
    // Stock Price API (Alpha Vantage)
    // Get your free key at: https://www.alphavantage.co/support/#api-key
    static var stockAPIKey: String {
        // 只从 Keychain 读取，确保安全
        KeychainManager.shared.getAPIKey(for: AppConfig.Keys.stockAPIKey) ?? 
        ProcessInfo.processInfo.environment["STOCK_API_KEY"] ?? ""
    }
    
    // News API
    // Get your free key at: https://newsapi.org/register
    static var newsAPIKey: String {
        // 只从 Keychain 读取，确保安全
        KeychainManager.shared.getAPIKey(for: AppConfig.Keys.newsAPIKey) ?? 
        ProcessInfo.processInfo.environment["NEWS_API_KEY"] ?? ""
    }
    
    // Check if API keys are configured
    static var hasValidStockAPIKey: Bool {
        let key = stockAPIKey
        return key != "YOUR_API_KEY_HERE" && !key.isEmpty
    }
    
    static var hasValidNewsAPIKey: Bool {
        let key = newsAPIKey
        return key != "YOUR_API_KEY_HERE" && !key.isEmpty
    }
}
