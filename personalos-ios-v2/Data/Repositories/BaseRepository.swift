import Foundation
import SwiftData

protocol Repository {
    associatedtype Entity: PersistentModel
    
    func fetch() async throws -> [Entity]
    func fetch(predicate: Predicate<Entity>?) async throws -> [Entity]
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func deleteAll() async throws
}

@MainActor
class BaseRepository<T: PersistentModel>: Repository {
    typealias Entity = T
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func fetch() async throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor)
    }
    
    func fetch(predicate: Predicate<T>?) async throws -> [T] {
        var descriptor = FetchDescriptor<T>()
        descriptor.predicate = predicate
        return try modelContext.fetch(descriptor)
    }
    
    func save(_ entity: T) async throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func delete(_ entity: T) async throws {
        modelContext.delete(entity)
        try modelContext.save()
    }
    
    func deleteAll() async throws {
        let entities = try await fetch()
        entities.forEach { modelContext.delete($0) }
        try modelContext.save()
    }
}

// MARK: - Specific Repositories
@MainActor
class TodoRepository: BaseRepository<TodoItem> {
    func fetchPending() async throws -> [TodoItem] {
        try await fetch(predicate: #Predicate { !$0.isCompleted })
    }
    
    func fetchCompleted() async throws -> [TodoItem] {
        try await fetch(predicate: #Predicate { $0.isCompleted })
    }
}

@MainActor
class ProjectRepository: BaseRepository<ProjectItem> {
    func fetchActive() async throws -> [ProjectItem] {
        try await fetch(predicate: #Predicate { $0.status == .active })
    }
}

@MainActor
class NewsRepository: BaseRepository<NewsItem> {
    func fetchBookmarked() async throws -> [NewsItem] {
        try await fetch()
    }
}

@MainActor
class TradeRepository: BaseRepository<TradeRecord> {
    func fetchRecent(days: Int = 90) async throws -> [TradeRecord] {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return try await fetch(predicate: #Predicate { $0.date > cutoffDate })
    }
}

@MainActor
class SocialPostRepository: BaseRepository<SocialPost> {}

@MainActor
class CodeSnippetRepository: BaseRepository<CodeSnippet> {}

@MainActor
class RSSFeedRepository: BaseRepository<RSSFeed> {}

@MainActor
class HabitRepository: BaseRepository<HabitItem> {}

// MARK: - Repository Container
@MainActor
class RepositoryContainer {
    static let shared = RepositoryContainer()
    
    private let modelContext: ModelContext
    
    lazy var todoRepository: TodoRepository = TodoRepository(modelContext: modelContext)
    lazy var projectRepository: ProjectRepository = ProjectRepository(modelContext: modelContext)
    lazy var newsRepository: NewsRepository = NewsRepository(modelContext: modelContext)
    lazy var tradeRepository: TradeRepository = TradeRepository(modelContext: modelContext)
    lazy var socialPostRepository: SocialPostRepository = SocialPostRepository(modelContext: modelContext)
    lazy var codeSnippetRepository: CodeSnippetRepository = CodeSnippetRepository(modelContext: modelContext)
    lazy var rssFeedRepository: RSSFeedRepository = RSSFeedRepository(modelContext: modelContext)
    lazy var habitRepository: HabitRepository = HabitRepository(modelContext: modelContext)
    
    init(modelContext: ModelContext? = nil) {
        if let context = modelContext {
            self.modelContext = context
        } else {
            // 创建默认容器
            let container = try! ModelContainer(for: 
                TodoItem.self, ProjectItem.self, NewsItem.self, TradeRecord.self,
                SocialPost.self, CodeSnippet.self, RSSFeed.self, HabitItem.self
            )
            self.modelContext = container.mainContext
        }
    }
}
