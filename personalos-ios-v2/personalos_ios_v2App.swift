import SwiftUI
import SwiftData

@main
struct personalos_ios_v2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var remoteConfig = RemoteConfigService.shared
    @State private var router = AppRouter()
    @State private var stockPriceService = StockPriceService()
    @State private var healthManager = HealthStoreManager()
    @State private var githubService = GitHubService()
    @State private var newsService = NewsService()

    init() {
        setupServices()
        setupTheme()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    iPadAppContainer()
                } else {
                    MainTabView()
                }
            }
            .onAppear {
                print("✅ App launched successfully")
            }
        }
        .modelContainer(for: [
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
        .environment(router)
        .environment(stockPriceService)
        .environment(healthManager)
        .environment(githubService)
        .environment(newsService)
        .environmentObject(serviceContainer)
        .environmentObject(themeManager)
        .environmentObject(remoteConfig)
    }
    
    private func setupServices() {
        #if DEBUG
        ServiceFactory.shared.configure(environment: .mock)
        #else
        ServiceFactory.shared.configure(environment: .production)
        #endif
        
        ServiceFactory.shared.setupServices(in: ServiceContainer.shared)
    }
    
    private func setupTheme() {
        ThemeManager.shared.applyTheme(ThemeManager.shared.currentTheme)
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


