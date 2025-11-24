import Foundation
import SwiftData

/// ✅ GOD-TIER OPTIMIZATION 3: Environment-injectable DI container
/// Eliminates global singleton for pure, testable architecture
/// Services are initialized only when first accessed, not at app launch

// MARK: - Environment Key for Dependency Injection

struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue: LazyServiceContainer? = nil
}

extension EnvironmentValues {
    var serviceContainer: LazyServiceContainer? {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}

@MainActor
final class LazyServiceContainer {
    // ✅ Keep shared for backward compatibility, but prefer environment injection
    static let shared: LazyServiceContainer = {
        #if DEBUG
        // ✅ P2 EXTREME: 在 DEBUG 模式下警告直接访问 shared
        // 强制开发者使用环境注入，保持架构纯洁性
        Logger.warning(
            "⚠️ LazyServiceContainer.shared accessed directly. Prefer @Environment(\\.serviceContainer) injection.",
            category: Logger.general
        )
        #endif
        return LazyServiceContainer()
    }()
    
    private var modelContainer: ModelContainer?
    private var cachedServices: [String: Any] = [:]
    
    // ✅ Allow creating isolated instances for testing
    init(modelContainer: ModelContainer? = nil) {
        self.modelContainer = modelContainer
    }
    
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
        return GitHubService(networkClient: NetworkClient(config: .github))
    }()
    
    private(set) lazy var newsService: NewsService = {
        Logger.log("🔧 Lazy-loading NewsService", category: Logger.general)
        return NewsService(networkClient: NetworkClient(config: .news))
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
        let repo = TodoRepository(modelContainer: container)
        cachedServices["TodoRepository"] = repo
        return repo
    }
    
    func socialPostRepository() -> SocialPostRepository? {
        guard let container = modelContainer else { return nil }
        
        if let cached = cachedServices["SocialPostRepository"] as? SocialPostRepository {
            return cached
        }
        
        Logger.log("🔧 Creating SocialPostRepository", category: Logger.general)
        let repo = SocialPostRepository(modelContainer: container)
        cachedServices["SocialPostRepository"] = repo
        return repo
    }
    
    func tradeRepository() -> TradeRepository? {
        guard let container = modelContainer else { return nil }
        
        if let cached = cachedServices["TradeRepository"] as? TradeRepository {
            return cached
        }
        
        Logger.log("🔧 Creating TradeRepository", category: Logger.general)
        let repo = TradeRepository(modelContainer: container)
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
    
    // ✅ GOD-TIER: Create isolated container for testing
    static func createTestContainer(modelContainer: ModelContainer) -> LazyServiceContainer {
        Logger.log("🧪 Creating isolated test container", category: Logger.general)
        return LazyServiceContainer(modelContainer: modelContainer)
    }
}

// MARK: - View Extension for Easy Access

extension View {
    /// Inject service container into environment
    func serviceContainer(_ container: LazyServiceContainer) -> some View {
        environment(\.serviceContainer, container)
    }
}
