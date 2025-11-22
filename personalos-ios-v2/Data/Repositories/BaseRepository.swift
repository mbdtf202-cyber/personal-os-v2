import SwiftData
import Foundation

@MainActor
protocol Repository {
    associatedtype Entity: PersistentModel
    var modelContext: ModelContext { get }
    func save(_ entity: Entity) async throws
    func delete(_ entity: Entity) async throws
    func fetchAll() async throws -> [Entity]
}

@MainActor
class BaseRepository<T: PersistentModel>: Repository {
    typealias Entity = T
    let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func save(_ entity: T) async throws {
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    func delete(_ entity: T) async throws {
        modelContext.delete(entity)
        try modelContext.save()
    }
    
    func fetchAll() async throws -> [T] {
        let descriptor = FetchDescriptor<T>()
        return try modelContext.fetch(descriptor)
    }
    
    func fetch() async throws -> [T] {
        return try await fetchAll()
    }
    
    func deleteAll() async throws {
        let descriptor = FetchDescriptor<T>()
        let items = try modelContext.fetch(descriptor)
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
}
