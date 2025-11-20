import Foundation

/// API Configuration
/// IMPORTANT: Never commit real API keys to version control
/// Use environment variables or .xcconfig files for production
enum APIConfig {
    // Stock Price API (Alpha Vantage)
    // Get your free key at: https://www.alphavantage.co/support/#api-key
    static var stockAPIKey: String {
        // Try to read from environment variable first
        if let key = ProcessInfo.processInfo.environment["STOCK_API_KEY"], !key.isEmpty {
            return key
        }
        // Fallback to placeholder (will use mock data)
        return "YOUR_API_KEY_HERE"
    }
    
    // News API
    // Get your free key at: https://newsapi.org/register
    static var newsAPIKey: String {
        if let key = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !key.isEmpty {
            return key
        }
        return "YOUR_API_KEY_HERE"
    }
    
    // Check if API keys are configured
    static var hasValidStockAPIKey: Bool {
        stockAPIKey != "YOUR_API_KEY_HERE" && !stockAPIKey.isEmpty
    }
    
    static var hasValidNewsAPIKey: Bool {
        newsAPIKey != "YOUR_API_KEY_HERE" && !newsAPIKey.isEmpty
    }
}
