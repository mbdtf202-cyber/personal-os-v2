import SwiftUI
import SwiftData

@main
struct personalos_ios_v2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var remoteConfig = RemoteConfigService.shared
    @State private var router = AppRouter()
    @State private var healthManager = HealthStoreManager()

    init() {
        DecimalTransformer.register()
        setupTheme()
        setupMonitoring()
    }
    
    private func setupMonitoring() {
        // 初始化 MetricKit（系统级监控）
        Task { @MainActor in
            _ = MetricKitManager.shared
        }
        
        // 记录应用启动
        AnalyticsLogger.shared.log(.appLaunched)
        
        // 检查 iCloud 状态
        CloudSyncManager.shared.checkiCloudStatus()
        
        Logger.log("✅ Monitoring systems initialized", category: Logger.general)
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(createModelContainer())
        .environment(router)
        .environment(healthManager)
        .environmentObject(themeManager)
        .environmentObject(remoteConfig)
    }
    
    private func createModelContainer() -> ModelContainer {
        let schema = Schema([
            TodoItem.self,
            HealthLog.self,
            SocialPost.self,
            ProjectItem.self,
            NewsItem.self,
            TradeRecord.self,
            AssetItem.self,
            RSSFeed.self,
            HabitItem.self,
            CodeSnippet.self
        ])
        
        // ✅ 检查是否配置了 CloudKit entitlements
        let hasCloudKitEntitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") != nil
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: hasCloudKitEntitlements ? .automatic : .none // 只在有 entitlements 时启用 iCloud
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            if hasCloudKitEntitlements {
                Logger.log("✅ ModelContainer created with iCloud sync", category: Logger.general)
            } else {
                Logger.log("✅ ModelContainer created (local storage only - CloudKit not configured)", category: Logger.general)
            }
            return container
        } catch {
            Logger.error("Failed to create ModelContainer: \(error)", category: Logger.general)
            
            #if DEBUG
            // ✅ 开发环境：自动删除旧数据库并重试（处理 Schema 迁移问题）
            Logger.warning("⚠️ Schema migration issue detected in DEBUG mode", category: Logger.general)
            Logger.warning("🗑️ Deleting old database and creating fresh container...", category: Logger.general)
            
            // 删除旧的数据库文件
            let storeURL = configuration.url
            try? FileManager.default.removeItem(at: storeURL)
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
            try? FileManager.default.removeItem(at: storeURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
            Logger.log("🗑️ Old database files removed", category: Logger.general)
            
            // 重试创建容器
            do {
                let container = try ModelContainer(for: schema, configurations: configuration)
                Logger.log("✅ ModelContainer created successfully after cleanup", category: Logger.general)
                return container
            } catch {
                Logger.error("Failed to create container even after cleanup: \(error)", category: Logger.general)
            }
            #endif
            
            // ✅ 如果启用了 CloudKit 但失败，尝试降级到本地存储
            if hasCloudKitEntitlements {
                Logger.warning("Falling back to local storage only", category: Logger.general)
                let fallbackConfig = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    allowsSave: true,
                    cloudKitDatabase: .none
                )
                
                #if DEBUG
                // 在 DEBUG 模式下，也尝试清理后重试
                let fallbackStoreURL = fallbackConfig.url
                try? FileManager.default.removeItem(at: fallbackStoreURL)
                try? FileManager.default.removeItem(at: fallbackStoreURL.deletingPathExtension().appendingPathExtension("sqlite-shm"))
                try? FileManager.default.removeItem(at: fallbackStoreURL.deletingPathExtension().appendingPathExtension("sqlite-wal"))
                #endif
                
                do {
                    let container = try ModelContainer(for: schema, configurations: fallbackConfig)
                    Logger.log("✅ ModelContainer created with local storage fallback", category: Logger.general)
                    return container
                } catch {
                    Logger.error("Fallback also failed: \(error)", category: Logger.general)
                    fatalError("Could not create ModelContainer even with fallback: \(error)")
                }
            }
            
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    private func setupTheme() {
        ThemeManager.shared.applyTheme(ThemeManager.shared.currentTheme)
    }
}

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var appDependency: AppDependency?
    
    var body: some View {
        Group {
            if let dependency = appDependency {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadAppContainer()
                        .environment(\.appDependency, dependency)
                        .environment(dependency.services.github)
                        .environment(dependency.services.news)
                } else {
                    MainTabView()
                        .environment(\.appDependency, dependency)
                        .environment(dependency.services.github)
                        .environment(dependency.services.news)
                }
            } else {
                LoadingView(message: "Initializing PersonalOS...")
            }
        }
        .onAppear {
            #if DEBUG
            appDependency = AppDependency(modelContext: modelContext, environment: .mock)
            #else
            appDependency = AppDependency(modelContext: modelContext, environment: .production)
            #endif
            
            Logger.log("✅ AppDependency initialized", category: Logger.general)
            
            if let dependency = appDependency {
                Task {
                    await DataBootstrapper.shared.bootstrap(dependency: dependency)
                }
            }
        }
    }
}

// LoadingView moved to Core/DesignSystem/Components/LoadingView.swift

// MARK: - Social Dashboard Wrapper
struct SocialDashboardViewWrapper: View {
    @Environment(\.appDependency) private var appDependency
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        if let dependency = appDependency {
            SocialDashboardView(viewModel: SocialDashboardViewModel(
                socialPostRepository: dependency.repositories.socialPost
            ))
        } else {
            LoadingView(message: "Loading Social...")
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @State private var showQuickNote = false

    var body: some View {
        ZStack {
            TabView(selection: Binding(
                get: { router.selectedTab },
                set: { router.selectedTab = $0 }
            )) {
                // 1. 🏠 Dashboard (含 Health)
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "square.grid.2x2.fill")
                    }
                    .tag(AppRouter.Tab.dashboard)
                
                // 2. 🚀 Growth (聚合 Projects, Knowledge, Tools)
                GrowthHubView()
                    .tabItem {
                        Label("Growth", systemImage: "hammer.fill")
                    }
                    .tag(AppRouter.Tab.growth)
                
                // 3. 💬 Social
                SocialDashboardViewWrapper()
                    .tabItem {
                        Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(AppRouter.Tab.social)
                
                // 4. 💰 Wealth
                TradingDashboardView()
                    .tabItem {
                        Label("Wealth", systemImage: "chart.line.uptrend.xyaxis")
                    }
                    .tag(AppRouter.Tab.wealth)

                // 5. 📰 News
                NewsFeedView()
                    .tabItem {
                        Label("News", systemImage: "newspaper.fill")
                    }
                    .tag(AppRouter.Tab.news)
            }
            .tint(AppTheme.primaryText)
            
            // Quick Note Overlay
            if showQuickNote {
                QuickNoteOverlay(isPresented: $showQuickNote)
            }
        }
    }
}


