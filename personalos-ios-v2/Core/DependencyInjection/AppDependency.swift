import SwiftUI
import SwiftData

enum ServiceEnvironment {
    case production
    case mock
    case test
}

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
        let news: NewsService
        let networkClient: NetworkClient
        let github: GitHubService
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
        
        let githubClient = NetworkClient(config: .github)
        
        switch environment {
        case .production:
            self.services = Services(
                health: HealthKitService(),
                news: NewsService(networkClient: NetworkClient(config: .news)),
                networkClient: networkClient,
                github: GitHubService(networkClient: githubClient)
            )
        case .mock, .test:
            // 测试环境使用真实服务，但可以配置为返回模拟数据
            self.services = Services(
                health: HealthKitService(),
                news: NewsService(networkClient: networkClient),
                networkClient: networkClient,
                github: GitHubService(networkClient: githubClient)
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
