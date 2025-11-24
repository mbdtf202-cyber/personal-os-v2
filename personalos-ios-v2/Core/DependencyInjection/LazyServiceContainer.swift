import Foundation
import SwiftData

/// ✅ EXTREME FIX 3: Lazy-loading DI container to optimize cold start time
/// Services are initialized only when first accessed, not at app launch
@MainActor
final class LazyServiceContainer {
    static let shared = LazyServiceContainer()
    
    private var modelContainer: ModelContainer?
    private var cachedServices: [String: Any] = [:]
    
    private init() {}
    
    func configure(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    // MARK: - Core Services (Eager - needed at startup)
    
    private(set) lazy var themeManager: ThemeManager = {
        Logger.log("🔧 Initializing ThemeManager", category: Logger.general)
        return ThemeManager.shared
    }()
    
    private(set) lazy var remoteConfig: RemoteConfigService = {
        Logger.log("🔧 Initializing RemoteConfigService", category: Logger.general)
        return RemoteConfigService.shared
    }()
    
    private(set) lazy var performanceMonitor: PerformanceMonitor = {
        Logger.log("🔧 Initializing PerformanceMonitor", category: Logger.general)
        return PerformanceMonitor.shared
    }()
    
    // MARK: - Feature Services (Lazy - loaded on demand)
    
    private(set) lazy var githubService: GitHubService = {
        Logger.log("🔧 Lazy-loading GitHubService", category: Logger.general)
        return GitHubService()
    }()
    
    private(set) lazy var newsService: NewsService = {
        Logger.log("🔧 Lazy-loading NewsService", category: Logger.general)
        return NewsService()
    }()
    
    private(set) lazy var stockPriceService: StockPriceService = {
        Logger.log("🔧 Lazy-loading StockPriceService", category: Logger.general)
        return StockPriceService()
    }()
    
    private(set) lazy var healthKitService: HealthKitService = {
        Logger.log("🔧 Lazy-loading HealthKitService", category: Logger.general)
        return HealthKitService()
    }()
    
    private(set) lazy var cloudSyncManager: CloudSyncManager = {
        Logger.log("🔧 Lazy-loading CloudSyncManager", category: Logger.general)
        return CloudSyncManager.shared
    }()
    
    // MARK: - Repositories (Lazy - created per feature)
    
    func todoRepository() -> TodoRepository? {
        guard let container = modelContainer else { return nil }
        
        if let cached = cachedServices["TodoRepository"] as? TodoRepository {
            return cached
        }
        
        Logger.log("🔧 Creating TodoRepository", category: Logger.general)
        let repo = TodoRepository(modelContext: ModelContext(container))
        cachedServices["TodoRepository"] = repo
        return repo
    }
    
    func socialPostRepository() -> SocialPostRepository? {
        guard let container = modelContainer else { return nil }
        
        if let cached = cachedServices["SocialPostRepository"] as? SocialPostRepository {
            return cached
        }
        
        Logger.log("🔧 Creating SocialPostRepository", category: Logger.general)
        let repo = SocialPostRepository(modelContext: ModelContext(container))
        cachedServices["SocialPostRepository"] = repo
        return repo
    }
    
    func tradeRepository() -> TradeRepository? {
        guard let container = modelContainer else { return nil }
        
        if let cached = cachedServices["TradeRepository"] as? TradeRepository {
            return cached
        }
        
        Logger.log("🔧 Creating TradeRepository", category: Logger.general)
        let repo = TradeRepository(modelContext: ModelContext(container))
        cachedServices["TradeRepository"] = repo
        return repo
    }
    
    // MARK: - Lifecycle
    
    func preloadCriticalServices() {
        // 预加载关键服务（在后台线程）
        Task.detached(priority: .utility) {
            await MainActor.run {
                _ = self.themeManager
                _ = self.remoteConfig
                _ = self.performanceMonitor
            }
        }
    }
    
    func clearCache() {
        cachedServices.removeAll()
        Logger.log("🗑️ Service cache cleared", category: Logger.general)
    }
}
