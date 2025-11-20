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
            AssetItem.self
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
                // 1. Dashboard
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "square.grid.2x2")
                    }
                    .tag(AppRouter.Tab.dashboard)
                
                // 2. Projects
                ProjectListView()
                    .tabItem {
                        Label("Projects", systemImage: "folder")
                    }
                    .tag(AppRouter.Tab.projects)
                
                // 3. Social & Blog
                SocialDashboardView()
                    .tabItem {
                        Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(AppRouter.Tab.social)
                
                // 4. News
                NewsFeedView()
                    .tabItem {
                        Label("News", systemImage: "newspaper")
                    }
                    .tag(AppRouter.Tab.news)

                // 5. More Apps
                MoreModulesView(themeStyle: $themeStyle)
                    .tabItem {
                        Label("Apps", systemImage: "circle.grid.3x3.fill")
                    }
                    .tag(AppRouter.Tab.tools)
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

// MARK: - More Modules View
struct MoreModulesView: View {
    @Binding var themeStyle: ThemeStyle

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        NavigationLink(destination: HealthHomeView()) {
                            ModuleCard(title: "Health", icon: "heart.fill", color: AppTheme.matcha)
                        }

                        NavigationLink(destination: TradingDashboardView()) {
                            ModuleCard(title: "Trading", icon: "chart.xyaxis.line", color: AppTheme.almond)
                        }

                        NavigationLink(destination: KnowledgeBaseView()) {
                            ModuleCard(title: "Knowledge", icon: "books.vertical.fill", color: .indigo)
                        }

                        NavigationLink(destination: ThemeGalleryView(themeStyle: $themeStyle)) {
                            ModuleCard(title: "Themes", icon: "paintbrush", color: AppTheme.lavender)
                        }
                        
                        NavigationLink(destination: SettingsView()) {
                            ModuleCard(title: "Settings", icon: "gearshape.fill", color: .gray)
                        }
                    }
                    .padding(20)
                }
                .navigationTitle("All Apps")
            }
        }
    }
}

struct ModuleCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
        .background(Color.white)
        .cornerRadius(24)
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }
}
