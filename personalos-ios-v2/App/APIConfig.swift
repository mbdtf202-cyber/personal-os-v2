import Foundation

/// API Configuration
/// IMPORTANT: Never commit real API keys to version control
/// All API keys are securely stored in Keychain
/// 
/// ⚠️ P1 Fix: ProcessInfo 环境变量在 Release 构建中不可用
/// 生产环境必须使用 Keychain 或编译时注入的 Secrets.swift
enum APIConfig {
    // Stock Price API (Alpha Vantage)
    // Get your free key at: https://www.alphavantage.co/support/#api-key
    static var stockAPIKey: String {
        // ✅ 优先级：Keychain → 混淆 Key → 编译时注入
        if let keychainKey = KeychainManager.shared.getAPIKey(for: AppConfig.Keys.stockAPIKey) {
            return keychainKey
        }
        
        if let obfuscatedKey = APIKeyObfuscator.getAPIKey(for: "stock") {
            return obfuscatedKey
        }
        
        // ⚠️ 仅用于本地开发，Release 构建时此值为空
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["STOCK_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        #endif
        
        // 生产环境回退：从编译时生成的 Secrets.swift 读取
        return CompileTimeSecrets.stockAPIKey
    }
    
    // News API
    // Get your free key at: https://newsapi.org/register
    static var newsAPIKey: String {
        // ✅ 优先级：Keychain → 混淆 Key → 编译时注入
        if let keychainKey = KeychainManager.shared.getAPIKey(for: AppConfig.Keys.newsAPIKey) {
            return keychainKey
        }
        
        if let obfuscatedKey = APIKeyObfuscator.getAPIKey(for: "news") {
            return obfuscatedKey
        }
        
        // ⚠️ 仅用于本地开发，Release 构建时此值为空
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        #endif
        
        // 生产环境回退：从编译时生成的 Secrets.swift 读取
        return CompileTimeSecrets.newsAPIKey
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
