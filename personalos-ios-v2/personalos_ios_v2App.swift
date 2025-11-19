import SwiftUI
import SwiftData

@main
struct personalos_ios_v2App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

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
        .modelContainer(for: [TodoItem.self, TradeRecord.self, SocialPost.self, HealthLog.self, HabitItem.self])
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @State private var selectedTab = 0
    @State private var showQuickNote = false
    @State private var themeStyle: ThemeStyle = .glass

    var body: some View {
        ZStack {
            TabView(selection: $selectedTab) {
                // 1. Dashboard
                DashboardView()
                    .tabItem {
                        Label("Home", systemImage: "square.grid.2x2")
                    }
                    .tag(0)
                
                // 2. Projects
                ProjectListView()
                    .tabItem {
                        Label("Projects", systemImage: "folder")
                    }
                    .tag(1)
                
                // 3. Social & Blog
                SocialDashboardView()
                    .tabItem {
                        Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    .tag(2)
                
                // 4. News
                NewsFeedView()
                    .tabItem {
                        Label("News", systemImage: "newspaper")
                    }
                    .tag(3)

                // 5. More Apps
                MoreModulesView(themeStyle: $themeStyle)
                    .tabItem {
                        Label("Apps", systemImage: "circle.grid.3x3.fill")
                    }
                    .tag(4)
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
