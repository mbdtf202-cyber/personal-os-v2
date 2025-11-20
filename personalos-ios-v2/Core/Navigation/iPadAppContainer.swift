import SwiftUI

struct iPadAppContainer: View {
    @State private var router = AppRouter()
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(selection: Binding(
                get: { router.selectedTab },
                set: { if let value = $0 { router.selectedTab = value } }
            )) {
                Section("Core") {
                    NavigationLink(value: AppRouter.Tab.dashboard) {
                        Label("Dashboard", systemImage: "square.grid.2x2")
                    }
                    NavigationLink(value: AppRouter.Tab.health) {
                        Label("Health", systemImage: "heart.fill")
                    }
                    NavigationLink(value: AppRouter.Tab.training) {
                        Label("Learning", systemImage: "book.fill")
                    }
                }
                
                Section("Finance") {
                    NavigationLink(value: AppRouter.Tab.trading) {
                        Label("Trading", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
                
                Section("Content") {
                    NavigationLink(value: AppRouter.Tab.social) {
                        Label("Social", systemImage: "pencil.and.scribble")
                    }
                    NavigationLink(value: AppRouter.Tab.news) {
                        Label("News", systemImage: "newspaper.fill")
                    }
                }
                
                Section("Work") {
                    NavigationLink(value: AppRouter.Tab.projects) {
                        Label("Projects", systemImage: "folder.fill")
                    }
                    NavigationLink(value: AppRouter.Tab.tools) {
                        Label("Tools", systemImage: "wrench.and.screwdriver.fill")
                    }
                }
            }
            .navigationTitle("Personal OS")
            .listStyle(.sidebar)
        } detail: {
            // Detail View
            Group {
                switch router.selectedTab {
                case .dashboard:
                    DashboardView()
                case .health:
                    HealthCenterView()
                case .training:
                    TrainingSystemView()
                case .trading:
                    TradingJournalView()
                case .social:
                    SocialBlogView()
                case .news:
                    NewsAggregatorView()
                case .projects:
                    ProjectHubView()
                case .tools:
                    ToolsView()
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    iPadAppContainer()
}
