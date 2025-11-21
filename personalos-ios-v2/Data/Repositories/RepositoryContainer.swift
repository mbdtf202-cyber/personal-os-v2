import Foundation
import SwiftData

@available(*, deprecated, message: "Use AppDependency.repositories instead")
@MainActor
class RepositoryContainer: ObservableObject {
    static var shared = RepositoryContainer()
    
    private var modelContext: ModelContext?
    
    lazy var todoRepository: TodoRepository = {
        TodoRepository(modelContext: getContext())
    }()
    
    lazy var projectRepository: ProjectRepository = {
        ProjectRepository(modelContext: getContext())
    }()
    
    lazy var newsRepository: NewsRepository = {
        NewsRepository(modelContext: getContext())
    }()
    
    lazy var tradeRepository: TradeRepository = {
        TradeRepository(modelContext: getContext())
    }()
    
    lazy var socialPostRepository: SocialPostRepository = {
        SocialPostRepository(modelContext: getContext())
    }()
    
    lazy var codeSnippetRepository: CodeSnippetRepository = {
        CodeSnippetRepository(modelContext: getContext())
    }()
    
    lazy var rssFeedRepository: RSSFeedRepository = {
        RSSFeedRepository(modelContext: getContext())
    }()
    
    lazy var habitRepository: HabitRepository = {
        HabitRepository(modelContext: getContext())
    }()
    
    private init() {}
    
    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    private func getContext() -> ModelContext {
        guard let context = modelContext else {
            fatalError("RepositoryContainer not configured. Call configure(modelContext:) first.")
        }
        return context
    }
}
