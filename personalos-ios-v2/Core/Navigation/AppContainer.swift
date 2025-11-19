import SwiftUI

struct AppContainer: View {
    @State private var router = AppRouter()
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            TabView(selection: $router.selectedTab) {
                DashboardView()
                    .tag(AppRouter.Tab.dashboard)
                    .tabItem {
                        Label("仪表盘", systemImage: "square.grid.2x2")
                    }
                
                HealthCenterView()
                    .tag(AppRouter.Tab.health)
                    .tabItem {
                        Label("健康", systemImage: "heart.fill")
                    }
                
                TrainingSystemView()
                    .tag(AppRouter.Tab.training)
                    .tabItem {
                        Label("学习", systemImage: "book.fill")
                    }
                
                TradingJournalView()
                    .tag(AppRouter.Tab.trading)
                    .tabItem {
                        Label("交易", systemImage: "chart.line.uptrend.xyaxis")
                    }
                
                SocialBlogView()
                    .tag(AppRouter.Tab.social)
                    .tabItem {
                        Label("创作", systemImage: "pencil.and.scribble")
                    }
                
                NewsAggregatorView()
                    .tag(AppRouter.Tab.news)
                    .tabItem {
                        Label("资讯", systemImage: "newspaper.fill")
                    }
                
                ProjectHubView()
                    .tag(AppRouter.Tab.projects)
                    .tabItem {
                        Label("项目", systemImage: "folder.fill")
                    }
                
                ToolsView()
                    .tag(AppRouter.Tab.tools)
                    .tabItem {
                        Label("工具", systemImage: "wrench.and.screwdriver.fill")
                    }
            }
            .tint(AppTheme.primaryText)
        }
        .onAppear {
            setupKeyboardShortcuts()
        }
    }
    
    private func setupKeyboardShortcuts() {
        #if targetEnvironment(macCatalyst) || os(macOS)
        // Cmd+K for global search
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "k" {
                router.selectedTab = .dashboard
                return nil
            }
            return event
        }
        #endif
    }
}
