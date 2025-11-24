import Foundation
import SwiftData

/// Schema version tracking
enum SchemaVersion: Int, Codable, Comparable {
    case v1 = 1
    case v2 = 2
    case v3 = 3
    case v4 = 4  // Current version with P0 fixes
    
    static var current: SchemaVersion { .v4 }
    
    static func < (lhs: SchemaVersion, rhs: SchemaVersion) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

/// Metadata about schema migrations
struct SchemaMetadata: Codable {
    let version: SchemaVersion
    let migratedAt: Date
    let backupURL: URL?
    let previousVersion: SchemaVersion?
}

/// Coordinates schema migrations with backup and rollback support
actor MigrationCoordinator {
    private let modelContainer: ModelContainer
    private let backupService: DataBackupService
    private let metadataKey = "schema_metadata"
    
    init(modelContainer: ModelContainer, backupService: DataBackupService) {
        self.modelContainer = modelContainer
        self.backupService = backupService
    }
    
    /// Check if migration is needed
    func needsMigration() async throws -> Bool {
        let currentVersion = try await getCurrentVersion()
        return currentVersion < SchemaVersion.current
    }
    
    /// Get the current schema version
    func getCurrentVersion() async throws -> SchemaVersion {
        guard let data = UserDefaults.standard.data(forKey: metadataKey),
              let metadata = try? JSONDecoder().decode(SchemaMetadata.self, from: data) else {
            return .v1  // Default to v1 if no metadata exists
        }
        return metadata.version
    }
    
    /// Perform migration from current version to target version
    func performMigration(context: ModelContext) async throws {
        let fromVersion = try await getCurrentVersion()
        let toVersion = SchemaVersion.current
        
        guard fromVersion < toVersion else {
            Logger.log("No migration needed. Current version: \(fromVersion.rawValue)", category: Logger.general)
            return
        }
        
        Logger.log("Starting migration from v\(fromVersion.rawValue) to v\(toVersion.rawValue)", category: Logger.general)
        
        // Create backup before migration
        let backupURL = try await createBackup()
        
        do {
            // Perform migration steps
            try await executeMigrationSteps(from: fromVersion, to: toVersion, context: context)
            
            // Save metadata
            let metadata = SchemaMetadata(
                version: toVersion,
                migratedAt: Date(),
                backupURL: backupURL,
                previousVersion: fromVersion
            )
            try saveMetadata(metadata)
            
            Logger.log("Migration completed successfully", category: Logger.general)
            
        } catch {
            Logger.error("Migration failed: \(error)", category: Logger.general)
            
            // Attempt rollback
            try await rollback(to: backupURL)
            throw MigrationError.migrationFailed(error)
        }
    }
    
    /// Execute migration steps for each version increment
    private func executeMigrationSteps(from: SchemaVersion, to: SchemaVersion, context: ModelContext) async throws {
        var currentVersion = from
        
        while currentVersion < to {
            let nextVersion = SchemaVersion(rawValue: currentVersion.rawValue + 1)!
            Logger.log("Migrating from v\(currentVersion.rawValue) to v\(nextVersion.rawValue)", category: Logger.general)
            
            try await migrateToVersion(nextVersion, context: context)
            currentVersion = nextVersion
        }
    }
    
    /// Migrate to a specific version
    private func migrateToVersion(_ version: SchemaVersion, context: ModelContext) async throws {
        switch version {
        case .v1:
            // Initial version, no migration needed
            break
            
        case .v2:
            // Add migration logic for v2
            try await migrateToV2(context: context)
            
        case .v3:
            // Add migration logic for v3
            try await migrateToV3(context: context)
            
        case .v4:
            // Add migration logic for v4 (P0 fixes)
            try await migrateToV4(context: context)
        }
    }
    
    /// Migration to v2
    private func migrateToV2(context: ModelContext) async throws {
        // Example: Add new fields, transform data, etc.
        Logger.log("Executing v2 migration", category: Logger.general)
        // Add specific migration logic here
    }
    
    /// Migration to v3
    private func migrateToV3(context: ModelContext) async throws {
        Logger.log("Executing v3 migration", category: Logger.general)
        // Add specific migration logic here
    }
    
    /// Migration to v4 (P0 fixes)
    private func migrateToV4(context: ModelContext) async throws {
        Logger.log("Executing v4 migration (P0 fixes)", category: Logger.general)
        
        // Migrate trading data from Double to Decimal
        // This will be implemented when we have the actual models
        
        // Add stable IDs to NewsItems
        // This will be implemented when we have the actual models
        
        // Clean up any sample data in production
        if EnvironmentManager.shared.environment == .production {
            // Remove sample data
            Logger.log("Cleaning up sample data in production", category: Logger.general)
        }
    }
    
    /// Create a backup before migration
    func createBackup() async throws -> URL {
        Logger.log("Creating backup before migration", category: Logger.general)
        return try await backupService.createBackup()
    }
    
    /// Restore from backup
    func restoreFromBackup(url: URL) async throws {
        Logger.log("Restoring from backup: \(url.path)", category: Logger.general)
        try await backupService.restoreFromBackup(url: url)
    }
    
    /// Rollback to previous version using backup
    func rollback(to backupURL: URL) async throws {
        Logger.log("Rolling back migration", category: Logger.general)
        
        do {
            try await restoreFromBackup(url: backupURL)
            Logger.log("Rollback completed successfully", category: Logger.general)
        } catch {
            Logger.error("Rollback failed: \(error)", category: Logger.general)
            throw MigrationError.rollbackFailed(error)
        }
    }
    
    /// Save migration metadata
    private func saveMetadata(_ metadata: SchemaMetadata) throws {
        let data = try JSONEncoder().encode(metadata)
        UserDefaults.standard.set(data, forKey: metadataKey)
    }
}

/// Migration errors
enum MigrationError: Error, LocalizedError {
    case migrationFailed(Error)
    case rollbackFailed(Error)
    case backupFailed(Error)
    case invalidVersion
    
    var errorDescription: String? {
        switch self {
        case .migrationFailed(let error):
            return "Migration failed: \(error.localizedDescription)"
        case .rollbackFailed(let error):
            return "Rollback failed: \(error.localizedDescription)"
        case .backupFailed(let error):
            return "Backup failed: \(error.localizedDescription)"
        case .invalidVersion:
            return "Invalid schema version"
        }
    }
}
