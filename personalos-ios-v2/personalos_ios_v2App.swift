import SwiftUI
import SwiftData

@main
struct personalos_ios_v2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var router = AppRouter()
    @State private var healthManager = HealthStoreManager()
    @State private var githubService = GitHubService()
    @State private var newsService = NewsService()
    @State private var stockPriceService = StockPriceService()

    init() {
        // 配置 UITabBar 的全局外观
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some Scene {
        WindowGroup {
            if UIDevice.current.userInterfaceIdiom == .pad {
                iPadAppContainer()
            } else {
                MainTabView()
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
        .environment(healthManager)
        .environment(githubService)
        .environment(newsService)
        .environment(stockPriceService)
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @Environment(AppRouter.self) private var router
    @State private var showQuickNote = false
    @State private var themeStyle: ThemeStyle = .glass

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
        .onAppear { AppTheme.apply(style: themeStyle) }
        .onChange(of: themeStyle) { _, newStyle in
            AppTheme.apply(style: newStyle)
        }
    }
}


