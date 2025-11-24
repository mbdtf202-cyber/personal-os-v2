import Foundation

/// 编译时 Feature Toggle 系统
/// 允许在编译时完全剔除某些功能，减小包体积
public enum FeatureFlags {
    
    // MARK: - 编译时 Feature Flags
    
    /// Dashboard 功能
    public static var isDashboardEnabled: Bool {
        #if FEATURE_DASHBOARD
        return true
        #else
        return false
        #endif
    }
    
    /// Trading Journal 功能
    public static var isTradingEnabled: Bool {
        #if FEATURE_TRADING
        return true
        #else
        return false
        #endif
    }
    
    /// Social Blog 功能
    public static var isSocialEnabled: Bool {
        #if FEATURE_SOCIAL
        return true
        #else
        return false
        #endif
    }
    
    /// News Aggregator 功能
    public static var isNewsEnabled: Bool {
        #if FEATURE_NEWS
        return true
        #else
        return false
        #endif
    }
    
    /// Health Center 功能
    public static var isHealthEnabled: Bool {
        #if FEATURE_HEALTH
        return true
        #else
        return false
        #endif
    }
    
    /// Project Hub 功能
    public static var isProjectHubEnabled: Bool {
        #if FEATURE_PROJECT_HUB
        return true
        #else
        return false
        #endif
    }
    
    /// Training System 功能
    public static var isTrainingEnabled: Bool {
        #if FEATURE_TRAINING
        return true
        #else
        return false
        #endif
    }
    
    /// Tools 功能
    public static var isToolsEnabled: Bool {
        #if FEATURE_TOOLS
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - 运行时 Feature Flags (Remote Config)
    
    /// 从远程配置获取的动态 Feature Flags
    public static func isFeatureEnabled(_ feature: String) -> Bool {
        #if DEBUG
        return true  // Debug 模式下所有功能默认开启
        #else
        return RemoteConfigService.shared.isFeatureEnabled(feature)
        #endif
    }
    
    // MARK: - 编译时优化验证
    
    /// 验证至少有一个功能被启用
    public static func validateFeatures() {
        let enabledFeatures = [
            isDashboardEnabled,
            isTradingEnabled,
            isSocialEnabled,
            isNewsEnabled,
            isHealthEnabled,
            isProjectHubEnabled,
            isTrainingEnabled,
            isToolsEnabled
        ]
        
        guard enabledFeatures.contains(true) else {
            fatalError("❌ 至少需要启用一个功能模块")
        }
        
        #if DEBUG
        let count = enabledFeatures.filter { $0 }.count
        print("✅ 已启用 \(count) 个功能模块")
        #endif
    }
}

// MARK: - Feature Flag 配置文件

/// 用于 CI/CD 的 Feature Flag 配置
/// 可以通过环境变量或配置文件控制编译时包含的功能
public struct FeatureFlagConfig: Codable {
    let dashboard: Bool
    let trading: Bool
    let social: Bool
    let news: Bool
    let health: Bool
    let projectHub: Bool
    let training: Bool
    let tools: Bool
    
    public static let `default` = FeatureFlagConfig(
        dashboard: true,
        trading: true,
        social: true,
        news: true,
        health: true,
        projectHub: true,
        training: true,
        tools: true
    )
    
    /// 从 JSON 文件加载配置
    public static func load(from path: String) throws -> FeatureFlagConfig {
        let data = try Data(contentsOf: URL(fileURLWithPath: path))
        return try JSONDecoder().decode(FeatureFlagConfig.self, from: data)
    }
    
    /// 生成编译器标志
    public func generateCompilerFlags() -> [String] {
        var flags: [String] = []
        if dashboard { flags.append("-DFEATURE_DASHBOARD") }
        if trading { flags.append("-DFEATURE_TRADING") }
        if social { flags.append("-DFEATURE_SOCIAL") }
        if news { flags.append("-DFEATURE_NEWS") }
        if health { flags.append("-DFEATURE_HEALTH") }
        if projectHub { flags.append("-DFEATURE_PROJECT_HUB") }
        if training { flags.append("-DFEATURE_TRAINING") }
        if tools { flags.append("-DFEATURE_TOOLS") }
        return flags
    }
}
