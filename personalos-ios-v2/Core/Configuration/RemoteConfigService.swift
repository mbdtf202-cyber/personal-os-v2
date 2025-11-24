import Foundation
import Combine

struct RemoteFeatureFlags: Codable {
    var healthCenter: Bool = true
    var projectHub: Bool = true
    var newsAggregator: Bool = true
    var tradingJournal: Bool = true
    var socialBlog: Bool = true
    var trainingSystem: Bool = true
    var tools: Bool = true
    
    var experimentalFeatures: ExperimentalFeatures = ExperimentalFeatures()
    
    struct ExperimentalFeatures: Codable {
        var aiInsights: Bool = false
        var crossModuleLinking: Bool = false
        var advancedAnalytics: Bool = false
        var offlineMode: Bool = false
    }
}

struct ABTestConfig: Codable {
    var userId: String?
    var experiments: [String: String] = [:]
}

@Observable
final class RemoteConfigService {
    static let shared = RemoteConfigService()
    
    private(set) var featureFlags: RemoteFeatureFlags
    private(set) var abTestConfig: ABTestConfig
    private(set) var isLoaded: Bool = false
    private(set) var apiKeys: [String: String] = [:]
    
    private let configURL: String
    private let cacheKey = "cached_remote_config"
    private let cacheExpirationKey = "config_cache_expiration"
    private let cacheValidityDuration: TimeInterval = 3600 // 1 hour
    
    // 🔧 P1 Fix: 使用统一的 NetworkClient
    private let networkClient: NetworkClient
    
    private init() {
        self.configURL = AppConfig.API.remoteConfigURL
        self.featureFlags = RemoteFeatureFlags()
        self.abTestConfig = ABTestConfig()
        self.networkClient = NetworkClient(config: .default)
        
        loadCachedConfig()
    }
    
    func fetchConfig() async {
        // 如果已经从缓存加载，直接返回
        if isLoaded {
            return
        }
        
        do {
            guard let url = URL(string: configURL), !configURL.isEmpty else {
                Logger.warning("Invalid remote config URL, using default config", category: Logger.general)
                await MainActor.run {
                    self.isLoaded = true
                }
                return
            }
            
            // 🔧 P1 Fix: 使用 NetworkClient 替代裸 URLSession
            let config: RemoteConfig = try await networkClient.request(url.absoluteString)
            
            await MainActor.run {
                self.featureFlags = config.featureFlags
                self.abTestConfig = config.abTestConfig
                self.isLoaded = true
                
                cacheConfig(config)
            }
        } catch {
            Logger.warning("Failed to fetch remote config: \(error.localizedDescription)", category: Logger.general)
            Logger.log("Using default/cached config", category: Logger.general)
            // Fallback to default config
            await MainActor.run {
                self.isLoaded = true
            }
        }
    }
    
    private func loadCachedConfig() {
        guard let data = UserDefaults.standard.data(forKey: cacheKey),
              let expiration = UserDefaults.standard.object(forKey: cacheExpirationKey) as? Date,
              expiration > Date() else {
            return
        }
        
        do {
            let config = try JSONDecoder().decode(RemoteConfig.self, from: data)
            self.featureFlags = config.featureFlags
            self.abTestConfig = config.abTestConfig
            self.isLoaded = true
        } catch {
            Logger.error("Failed to load cached config: \(error)", category: Logger.general)
        }
    }
    
    private func cacheConfig(_ config: RemoteConfig) {
        do {
            let data = try JSONEncoder().encode(config)
            UserDefaults.standard.set(data, forKey: cacheKey)
            UserDefaults.standard.set(Date().addingTimeInterval(cacheValidityDuration), forKey: cacheExpirationKey)
        } catch {
            Logger.error("Failed to cache config: \(error)", category: Logger.general)
        }
    }
    
    func isFeatureEnabled(_ feature: String) -> Bool {
        switch feature {
        case "healthCenter": return featureFlags.healthCenter
        case "projectHub": return featureFlags.projectHub
        case "newsAggregator": return featureFlags.newsAggregator
        case "tradingJournal": return featureFlags.tradingJournal
        case "socialBlog": return featureFlags.socialBlog
        case "trainingSystem": return featureFlags.trainingSystem
        case "tools": return featureFlags.tools
        case "aiInsights": return featureFlags.experimentalFeatures.aiInsights
        case "crossModuleLinking": return featureFlags.experimentalFeatures.crossModuleLinking
        case "advancedAnalytics": return featureFlags.experimentalFeatures.advancedAnalytics
        case "offlineMode": return featureFlags.experimentalFeatures.offlineMode
        default: return false
        }
    }
    
    func getExperimentVariant(_ experimentName: String) -> String? {
        return abTestConfig.experiments[experimentName]
    }
    
    func getAPIKey(for service: String) -> String? {
        return apiKeys[service]
    }
    
    func updateAPIKeys(_ keys: [String: String]) {
        self.apiKeys = keys
    }
    
    /// ✅ P0 Fix: 添加 getBool 方法供 SSLPinningManager 使用
    func getBool(_ key: String, defaultValue: Bool = false) -> Bool {
        // 可以从 Remote Config 读取布尔值
        // 目前返回默认值，后续可扩展
        return defaultValue
    }
    
    /// ✅ P0 Fix: 添加 getString 方法供 SSLPinningManager 使用
    func getString(_ key: String, defaultValue: String? = nil) -> String? {
        // 可以从 Remote Config 读取字符串值
        // 目前返回默认值，后续可扩展
        return defaultValue
    }
}

struct RemoteConfig: Codable {
    var featureFlags: RemoteFeatureFlags
    var abTestConfig: ABTestConfig
}
