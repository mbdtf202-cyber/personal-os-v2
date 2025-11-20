import SwiftUI
import SwiftData

@main
struct personalos_ios_v2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var serviceContainer = ServiceContainer.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var remoteConfig = RemoteConfigService.shared
    @State private var router = AppRouter()

    init() {
        setupServices()
        setupTheme()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if remoteConfig.isLoaded {
                    if UIDevice.current.userInterfaceIdiom == .pad {
                        iPadAppContainer()
                    } else {
                        MainTabView()
                    }
                } else {
                    LoadingView(message: "Initializing...")
                }
            }
            .task {
                await remoteConfig.fetchConfig()
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
    @EnvironmentObject var remoteConfig: RemoteConfigService
    @State private var showQuickNote = false

    var body: some View {
        ZStack {
            TabView(selection: Binding(
                get: { router.selectedTab },
                set: { router.selectedTab = $0 }
            )) {
                // 1. 🏠 Dashboard (含 Health)
                if remoteConfig.isFeatureEnabled("healthCenter") {
                    DashboardView()
                        .tabItem {
                            Label("Home", systemImage: "square.grid.2x2.fill")
                        }
                        .tag(AppRouter.Tab.dashboard)
                }
                
                // 2. 🚀 Growth (聚合 Projects, Knowledge, Tools)
                if remoteConfig.isFeatureEnabled("projectHub") || 
                   remoteConfig.isFeatureEnabled("trainingSystem") ||
                   remoteConfig.isFeatureEnabled("tools") {
                    GrowthHubView()
                        .tabItem {
                            Label("Growth", systemImage: "hammer.fill")
                        }
                        .tag(AppRouter.Tab.growth)
                }
                
                // 3. 💬 Social
                if remoteConfig.isFeatureEnabled("socialBlog") {
                    SocialDashboardView()
                        .tabItem {
                            Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                        }
                        .tag(AppRouter.Tab.social)
                }
                
                // 4. 💰 Wealth
                if remoteConfig.isFeatureEnabled("tradingJournal") {
                    TradingDashboardView()
                        .tabItem {
                            Label("Wealth", systemImage: "chart.line.uptrend.xyaxis")
                        }
                        .tag(AppRouter.Tab.wealth)
                }

                // 5. 📰 News
                if remoteConfig.isFeatureEnabled("newsAggregator") {
                    NewsFeedView()
                        .tabItem {
                            Label("News", systemImage: "newspaper.fill")
                        }
                        .tag(AppRouter.Tab.news)
                }
            }
            .tint(AppTheme.primaryText)
            
            // Quick Note Overlay
            if showQuickNote {
                QuickNoteOverlay(isPresented: $showQuickNote)
            }
        }
    }
}


