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
        // ✅ 简化优先级：Keychain → 编译时注入 → DEBUG 环境变量
        // 移除 APIKeyObfuscator（过度设计且未维护）
        
        // 1. 优先从 Keychain 读取（用户运行时配置）
        if let keychainKey = KeychainManager.shared.getAPIKey(for: AppConfig.Keys.stockAPIKey) {
            return keychainKey
        }
        
        // 2. 生产环境：从编译时注入的密钥读取
        if !CompileTimeSecrets.stockAPIKey.contains("PLACEHOLDER") {
            return CompileTimeSecrets.stockAPIKey
        }
        
        // 3. 开发环境回退：Xcode Scheme 环境变量
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["STOCK_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        #endif
        
        return ""
    }
    
    // News API
    // Get your free key at: https://newsapi.org/register
    static var newsAPIKey: String {
        // ✅ 简化优先级：Keychain → 编译时注入 → DEBUG 环境变量
        // 移除 APIKeyObfuscator（过度设计且未维护）
        
        // 1. 优先从 Keychain 读取（用户运行时配置）
        if let keychainKey = KeychainManager.shared.getAPIKey(for: AppConfig.Keys.newsAPIKey) {
            return keychainKey
        }
        
        // 2. 生产环境：从编译时注入的密钥读取
        if !CompileTimeSecrets.newsAPIKey.contains("PLACEHOLDER") {
            return CompileTimeSecrets.newsAPIKey
        }
        
        // 3. 开发环境回退：Xcode Scheme 环境变量
        #if DEBUG
        if let envKey = ProcessInfo.processInfo.environment["NEWS_API_KEY"], !envKey.isEmpty {
            return envKey
        }
        #endif
        
        return ""
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
