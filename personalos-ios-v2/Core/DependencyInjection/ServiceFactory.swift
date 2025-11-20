import Foundation

enum ServiceEnvironment {
    case production
    case mock
    case test
}

@MainActor
class ServiceFactory {
    static let shared = ServiceFactory()
    private var environment: ServiceEnvironment = .production
    
    private init() {}
    
    func configure(environment: ServiceEnvironment) {
        self.environment = environment
    }
    
    func setupServices(in container: ServiceContainer) {
        switch environment {
        case .production:
            setupProductionServices(in: container)
        case .mock:
            setupMockServices(in: container)
        case .test:
            setupTestServices(in: container)
        }
    }
    
    private func setupProductionServices(in container: ServiceContainer) {
        container.register(HealthServiceProtocol.self) {
            HealthKitService()
        }
        
        container.register(GitHubServiceProtocol.self) {
            GitHubService()
        }
        
        container.register(NewsServiceProtocol.self) {
            NewsService()
        }
        
        container.register(StockServiceProtocol.self) {
            StockPriceService()
        }
    }
    
    private func setupMockServices(in container: ServiceContainer) {
        container.register(HealthServiceProtocol.self) {
            MockHealthService()
        }
        
        container.register(GitHubServiceProtocol.self) {
            MockGitHubService()
        }
        
        container.register(NewsServiceProtocol.self) {
            MockNewsService()
        }
        
        container.register(StockServiceProtocol.self) {
            MockStockService()
        }
    }
    
    private func setupTestServices(in container: ServiceContainer) {
        setupMockServices(in: container)
    }
}

// MARK: - Mock Services
class MockHealthService: HealthServiceProtocol {
    func requestAuthorization() async throws {}
    
    func fetchDailySteps() async throws -> Double {
        return 8500
    }
    
    func fetchWeeklyActivity() async throws -> [String: Double] {
        return ["Mon": 8000, "Tue": 9500, "Wed": 7200, "Thu": 10000, "Fri": 8500, "Sat": 6000, "Sun": 5500]
    }
}

class MockGitHubService: GitHubServiceProtocol {
    func fetchRepositories() async throws -> [GitHubRepository] {
        return []
    }
    
    func fetchIssues(repo: String) async throws -> [GitHubIssue] {
        return []
    }
}

class MockNewsService: NewsServiceProtocol {
    func fetchNews(category: String?) async throws -> [NewsArticle] {
        return []
    }
    
    func searchNews(query: String) async throws -> [NewsArticle] {
        return []
    }
}

class MockStockService: StockServiceProtocol {
    func fetchQuote(symbol: String) async throws -> StockQuote {
        return StockQuote(symbol: symbol, price: 150.0, change: 2.5, changePercent: 1.7)
    }
    
    func fetchMultipleQuotes(symbols: [String]) async throws -> [StockQuote] {
        return symbols.map { StockQuote(symbol: $0, price: 150.0, change: 2.5, changePercent: 1.7) }
    }
}
