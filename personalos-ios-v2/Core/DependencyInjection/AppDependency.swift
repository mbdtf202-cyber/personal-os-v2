import SwiftUI
import SwiftData

@MainActor
struct AppDependency {
    let modelContext: ModelContext
    let repositories: Repositories
    let services: Services
    
    struct Repositories {
        let todo: TodoRepository
        let project: ProjectRepository
        let news: NewsRepository
        let trade: TradeRepository
        let socialPost: SocialPostRepository
        let codeSnippet: CodeSnippetRepository
        let rssFeed: RSSFeedRepository
        let habit: HabitRepository
    }
    
    struct Services {
        let health: HealthServiceProtocol
        let github: GitHubServiceProtocol
        let news: NewsServiceProtocol
        let stock: StockServiceProtocol
        let networkClient: NetworkClient
    }
    
    init(modelContext: ModelContext, environment: ServiceEnvironment = .production) {
        self.modelContext = modelContext
        
        self.repositories = Repositories(
            todo: TodoRepository(modelContext: modelContext),
            project: ProjectRepository(modelContext: modelContext),
            news: NewsRepository(modelContext: modelContext),
            trade: TradeRepository(modelContext: modelContext),
            socialPost: SocialPostRepository(modelContext: modelContext),
            codeSnippet: CodeSnippetRepository(modelContext: modelContext),
            rssFeed: RSSFeedRepository(modelContext: modelContext),
            habit: HabitRepository(modelContext: modelContext)
        )
        
        let networkClient = NetworkClient(config: .default)
        
        switch environment {
        case .production:
            self.services = Services(
                health: HealthKitService(),
                github: GitHubService(networkClient: NetworkClient(config: .github)),
                news: NewsService(networkClient: NetworkClient(config: .news)),
                stock: StockPriceService(networkClient: NetworkClient(config: .stocks)),
                networkClient: networkClient
            )
        case .mock, .test:
            self.services = Services(
                health: MockHealthService(),
                github: MockGitHubService(),
                news: MockNewsService(),
                stock: MockStockService(),
                networkClient: networkClient
            )
        }
    }
}

struct AppDependencyKey: EnvironmentKey {
    static let defaultValue: AppDependency? = nil
}

extension EnvironmentValues {
    var appDependency: AppDependency? {
        get { self[AppDependencyKey.self] }
        set { self[AppDependencyKey.self] = newValue }
    }
}
