import Foundation
import SwiftUI
import Combine

// MARK: - Service Protocols
protocol HealthServiceProtocol {
    func requestAuthorization() async throws
    func fetchDailySteps() async throws -> Double
    func fetchWeeklyActivity() async throws -> [String: Double]
}

protocol GitHubServiceProtocol {
    func fetchRepositories() async throws -> [GitHubRepository]
    func fetchIssues(repo: String) async throws -> [GitHubIssue]
}

protocol NewsServiceProtocol {
    func fetchNews(category: String?) async throws -> [NewsArticle]
    func searchNews(query: String) async throws -> [NewsArticle]
}

protocol StockServiceProtocol {
    func fetchQuote(symbol: String) async throws -> StockQuote
    func fetchMultipleQuotes(symbols: [String]) async throws -> [StockQuote]
}

// MARK: - Service Container
@MainActor
class ServiceContainer: ObservableObject {
    static let shared = ServiceContainer()
    
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]
    
    private init() {}
    
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }
    
    func resolve<T>(_ type: T.Type) -> T {
        let key = String(describing: type)
        
        if let service = services[key] as? T {
            return service
        }
        
        guard let factory = factories[key] else {
            fatalError("Service \(key) not registered")
        }
        
        let service = factory() as! T
        services[key] = service
        return service
    }
    
    func registerSingleton<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }
    
    func reset() {
        services.removeAll()
    }
}

// MARK: - Environment Key
struct ServiceContainerKey: EnvironmentKey {
    static let defaultValue = ServiceContainer.shared
}

extension EnvironmentValues {
    var serviceContainer: ServiceContainer {
        get { self[ServiceContainerKey.self] }
        set { self[ServiceContainerKey.self] = newValue }
    }
}
