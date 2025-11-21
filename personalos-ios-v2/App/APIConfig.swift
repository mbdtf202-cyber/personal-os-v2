import Foundation

/// API Configuration
/// IMPORTANT: Never commit real API keys to version control
/// Use environment variables or .xcconfig files for production
enum APIConfig {
    // Stock Price API (Alpha Vantage)
    // Get your free key at: https://www.alphavantage.co/support/#api-key
    static var stockAPIKey: String {
        AppConfig.API.stockAPIKey
    }
    
    // News API
    // Get your free key at: https://newsapi.org/register
    static var newsAPIKey: String {
        AppConfig.API.newsAPIKey
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
