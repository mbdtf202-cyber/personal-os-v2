import Foundation

/// 编译时注入的密钥配置
/// ⚠️ 此文件应由 CI/CD 构建脚本在编译时生成
/// 本地开发时使用占位符，生产构建时替换为真实值
enum CompileTimeSecrets {
    // 这些值应在 CI/CD 的 Build Phase 中通过脚本替换
    // 例如：sed -i '' 's/PLACEHOLDER_STOCK_KEY/'"$STOCK_API_KEY"'/g' CompileTimeSecrets.swift
    
    static let stockAPIKey: String = "PLACEHOLDER_STOCK_KEY"
    static let newsAPIKey: String = "PLACEHOLDER_NEWS_KEY"
    
    // 验证密钥是否已正确注入
    static var isConfigured: Bool {
        return !stockAPIKey.contains("PLACEHOLDER") && !newsAPIKey.contains("PLACEHOLDER")
    }
}
