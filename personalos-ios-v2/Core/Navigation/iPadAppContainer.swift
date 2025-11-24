import SwiftUI

struct iPadAppContainer: View {
    @Environment(AppRouter.self) private var router
    @Environment(\.appDependency) private var appDependency
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            // Sidebar
            List(selection: Binding(
                get: { router.selectedTab },
                set: { if let value = $0 { router.selectedTab = value } }
            )) {
                Section("Main") {
                    NavigationLink(value: AppRouter.Tab.dashboard) {
                        Label("Dashboard", systemImage: "square.grid.2x2.fill")
                    }
                    NavigationLink(value: AppRouter.Tab.growth) {
                        Label("Growth", systemImage: "hammer.fill")
                    }
                }
                
                Section("Content") {
                    NavigationLink(value: AppRouter.Tab.social) {
                        Label("Social", systemImage: "bubble.left.and.bubble.right.fill")
                    }
                    NavigationLink(value: AppRouter.Tab.news) {
                        Label("News", systemImage: "newspaper.fill")
                    }
                }
                
                Section("Finance") {
                    NavigationLink(value: AppRouter.Tab.wealth) {
                        Label("Wealth", systemImage: "chart.line.uptrend.xyaxis")
                    }
                }
            }
            .navigationTitle("Personal OS")
            .listStyle(.sidebar)
        } detail: {
            // Detail View
            Group {
                if let appDependency = appDependency {
                    switch router.selectedTab {
                    case .dashboard:
                        DashboardView()
                    case .growth:
                        GrowthHubView()
                    case .social:
                        SocialDashboardView(
                            viewModel: SocialDashboardViewModel(
                                socialPostRepository: appDependency.repositories.socialPost
                            )
                        )
                    case .wealth:
                        TradingDashboardView()
                    case .news:
                        NewsFeedView()
                    }
                } else {
                    EmptyStateView(
                        icon: "exclamationmark.triangle",
                        title: "Initialization Error",
                        message: "App dependencies not available"
                    )
                }
            }
        }
        .navigationSplitViewStyle(.balanced)
    }
}

#Preview {
    iPadAppContainer()
}
