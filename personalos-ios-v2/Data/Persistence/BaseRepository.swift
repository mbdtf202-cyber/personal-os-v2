import Foundation
import SwiftData

/// Thread-safe base repository for SwiftData operations
/// All database operations are isolated using actor to prevent data races
actor BaseRepository<T: PersistentModel> {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Fetch all items matching the predicate
    func fetch(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = []) async throws -> [T] {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch items with a limit
    func fetch(predicate: Predicate<T>? = nil, sortBy: [SortDescriptor<T>] = [], limit: Int) async throws -> [T] {
        var descriptor = FetchDescriptor<T>(predicate: predicate, sortBy: sortBy)
        descriptor.fetchLimit = limit
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch a single item by predicate
    func fetchOne(predicate: Predicate<T>) async throws -> T? {
        var descriptor = FetchDescriptor<T>(predicate: predicate)
        descriptor.fetchLimit = 1
        let results = try modelContext.fetch(descriptor)
        return results.first
    }
    
    /// Count items matching the predicate
    func count(predicate: Predicate<T>? = nil) async throws -> Int {
        let descriptor = FetchDescriptor<T>(predicate: predicate)
        return try modelContext.fetchCount(descriptor)
    }
    
    /// Save a new item or update existing
    func save(_ item: T) async throws {
        modelContext.insert(item)
        try modelContext.save()
    }
    
    /// Save multiple items
    func saveAll(_ items: [T]) async throws {
        for item in items {
            modelContext.insert(item)
        }
        try modelContext.save()
    }
    
    /// Delete an item
    func delete(_ item: T) async throws {
        modelContext.delete(item)
        try modelContext.save()
    }
    
    /// Delete multiple items
    func deleteAll(_ items: [T]) async throws {
        for item in items {
            modelContext.delete(item)
        }
        try modelContext.save()
    }
    
    /// Delete all items matching predicate
    func deleteAll(where predicate: Predicate<T>) async throws {
        let items = try await fetch(predicate: predicate)
        try await deleteAll(items)
    }
    
    /// Perform a custom operation within the ModelContext
    func perform<Result>(_ block: @escaping (ModelContext) throws -> Result) async throws -> Result {
        let result = try block(modelContext)
        if modelContext.hasChanges {
            try modelContext.save()
        }
        return result
    }
    
    /// Check if any items exist matching the predicate
    func exists(predicate: Predicate<T>) async throws -> Bool {
        let count = try await count(predicate: predicate)
        return count > 0
    }
}

/// Extension for common query patterns
extension BaseRepository {
    /// Fetch all items
    func fetchAll() async throws -> [T] {
        return try await fetch()
    }
    
    /// Delete all items
    func deleteAll() async throws {
        let items = try await fetchAll()
        try await deleteAll(items)
    }
    
    /// Get total count
    func totalCount() async throws -> Int {
        return try await count()
    }
}
