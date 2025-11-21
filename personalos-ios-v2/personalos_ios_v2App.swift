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
        
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            cloudKitDatabase: .automatic // 启用 iCloud 同步
        )
        
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            Logger.log("✅ ModelContainer created with iCloud sync", category: Logger.general)
            return container
        } catch {
            Logger.error("Failed to create ModelContainer: \(error)", category: Logger.general)
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
                } else {
                    MainTabView()
                        .environment(\.appDependency, dependency)
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
        }
    }
}

// MARK: - Loading View
struct LoadingView: View {
    let message: String
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                LoadingSpinner()
                    .scaleEffect(1.5)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                
                LoadingDots()
            }
            .animateOnAppear()
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
                SocialDashboardView()
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


