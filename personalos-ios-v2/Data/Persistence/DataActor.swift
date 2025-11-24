import Foundation
import SwiftData

/// Global actor for isolating all SwiftData write operations
/// This ensures thread safety by serializing all database access
@globalActor
actor DataActor {
    static let shared = DataActor()
    
    private init() {}
}

/// Thread-safe wrapper for ModelContext operations
actor ModelContextWrapper {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Perform a read operation
    func fetch<T: PersistentModel>(
        _ descriptor: FetchDescriptor<T>
    ) throws -> [T] {
        return try modelContext.fetch(descriptor)
    }
    
    /// Perform a write operation
    func insert<T: PersistentModel>(_ model: T) {
        modelContext.insert(model)
    }
    
    /// Perform a delete operation
    func delete<T: PersistentModel>(_ model: T) {
        modelContext.delete(model)
    }
    
    /// Save changes to persistent store
    func save() throws {
        if modelContext.hasChanges {
            try modelContext.save()
        }
    }
    
    /// Execute a block within the ModelContext
    func perform<T>(_ block: @escaping () throws -> T) throws -> T {
        return try block()
    }
    
    /// Execute an async block within the ModelContext
    func performAsync<T>(_ block: @escaping () async throws -> T) async throws -> T {
        return try await block()
    }
}
