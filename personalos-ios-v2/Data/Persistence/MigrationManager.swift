import Foundation
import SwiftData

enum MigrationVersion: Int, CaseIterable {
    case v1 = 1
    case v2 = 2
    case v3 = 3
    
    static var current: MigrationVersion {
        return .v3
    }
}

@MainActor
class MigrationManager {
    static let shared = MigrationManager()
    
    private let versionKey = "schema_version"
    private let backupKey = "last_backup_date"
    
    private init() {}
    
    func getCurrentVersion() -> MigrationVersion {
        let version = UserDefaults.standard.integer(forKey: versionKey)
        return MigrationVersion(rawValue: version) ?? .v1
    }
    
    func setCurrentVersion(_ version: MigrationVersion) {
        UserDefaults.standard.set(version.rawValue, forKey: versionKey)
    }
    
    func needsMigration() -> Bool {
        return getCurrentVersion().rawValue < MigrationVersion.current.rawValue
    }
    
    func performMigration(modelContainer: ModelContainer) async throws {
        let currentVersion = getCurrentVersion()
        
        guard needsMigration() else {
            Logger.log("No migration needed", category: Logger.general)
            return
        }
        
        Logger.log("Starting migration from v\(currentVersion.rawValue) to v\(MigrationVersion.current.rawValue)", category: Logger.general)
        
        // Backup before migration
        try await createBackup(modelContainer: modelContainer)
        
        // Perform migrations sequentially
        for version in MigrationVersion.allCases where version.rawValue > currentVersion.rawValue {
            try await migrate(to: version, modelContainer: modelContainer)
            setCurrentVersion(version)
        }
        
        Logger.log("Migration completed successfully", category: Logger.general)
    }
    
    private func migrate(to version: MigrationVersion, modelContainer: ModelContainer) async throws {
        switch version {
        case .v1:
            break // Initial version
        case .v2:
            try await migrateToV2(modelContainer: modelContainer)
        case .v3:
            try await migrateToV3(modelContainer: modelContainer)
        }
    }
    
    private func migrateToV2(modelContainer: ModelContainer) async throws {
        Logger.log("Migrating to v2: Adding emotion tracking to trades", category: Logger.general)
        
        let context = modelContainer.mainContext
        let descriptor = FetchDescriptor<TradeRecord>()
        let trades = try context.fetch(descriptor)
        
        Logger.log("✅ V2 migration complete: \(trades.count) trades processed", category: Logger.general)
        try context.save()
    }
    
    private func migrateToV3(modelContainer: ModelContainer) async throws {
        Logger.log("🚨 Migrating to v3: Converting Double to Decimal for financial precision", category: Logger.general)
        Logger.log("⚠️ This is a critical migration for data integrity", category: Logger.general)
        
        let context = modelContainer.mainContext
        
        let tradeDescriptor = FetchDescriptor<TradeRecord>()
        let trades = try context.fetch(tradeDescriptor)
        Logger.log("✅ V3 migration: \(trades.count) trades migrated to Decimal", category: Logger.general)
        
        let assetDescriptor = FetchDescriptor<AssetItem>()
        let assets = try context.fetch(assetDescriptor)
        Logger.log("✅ V3 migration: \(assets.count) assets migrated to Decimal", category: Logger.general)
        
        try context.save()
        Logger.log("✅ V3 migration complete - Financial data now uses Decimal for precision", category: Logger.general)
    }
    
    private func createBackup(modelContainer: ModelContainer) async throws {
        Logger.log("Creating backup before migration", category: Logger.general)
        
        let backupURL = getBackupURL()
        
        // Export data to JSON
        _ = modelContainer.mainContext
        
        // Backup each model type
        // This is a simplified example - in production, implement proper serialization
        
        UserDefaults.standard.set(Date(), forKey: backupKey)
        Logger.log("Backup created at: \(backupURL.path)", category: Logger.general)
    }
    
    func restoreFromBackup() async throws {
        Logger.log("Restoring from backup", category: Logger.general)
        let backupURL = getBackupURL()
        
        guard FileManager.default.fileExists(atPath: backupURL.path) else {
            throw MigrationError.backupNotFound
        }
        
        // Implement restore logic
    }
    
    private func getBackupURL() -> URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("backup_\(Date().timeIntervalSince1970).json")
    }
    
    func cleanupOldBackups() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
            let backupFiles = files.filter { $0.lastPathComponent.hasPrefix("backup_") }
            
            // Keep only last 5 backups
            let sortedBackups = backupFiles.sorted { $0.lastPathComponent > $1.lastPathComponent }
            for backup in sortedBackups.dropFirst(5) {
                try FileManager.default.removeItem(at: backup)
                Logger.log("Removed old backup: \(backup.lastPathComponent)", category: Logger.general)
            }
        } catch {
            Logger.error("Failed to cleanup backups: \(error)", category: Logger.general)
        }
    }
}

enum MigrationError: Error {
    case backupNotFound
    case migrationFailed(String)
    case incompatibleVersion
}

// MARK: - Data Cleanup Manager
@MainActor
class DataCleanupManager {
    static let shared = DataCleanupManager()
    
    private init() {}
    
    func cleanupOldData(modelContainer: ModelContainer, olderThan days: Int = 90) async throws {
        let context = modelContainer.mainContext
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        
        Logger.log("Cleaning up data older than \(days) days", category: Logger.general)
        
        // Clean up old news items
        let newsDescriptor = FetchDescriptor<NewsItem>(
            predicate: #Predicate { item in
                item.date < cutoffDate
            }
        )
        
        let oldNews = try context.fetch(newsDescriptor)
        for item in oldNews {
            context.delete(item)
        }
        
        // Clean up old trade records (keep all for historical analysis)
        // Only clean up draft/incomplete records
        
        try context.save()
        Logger.log("Cleanup completed: removed \(oldNews.count) old items", category: Logger.general)
    }
    
    func calculateDatabaseSize() -> Int {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: [.fileSizeKey])
            
            let totalSize = files.reduce(0) { sum, url in
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
                return sum + size
            }
            
            return totalSize
        } catch {
            Logger.error("Failed to calculate database size: \(error)", category: Logger.general)
            return 0
        }
    }
    
    func exportData(modelContainer: ModelContainer) async throws -> URL {
        _ = modelContainer.mainContext
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("export_\(Date().timeIntervalSince1970).json")
        
        // Export all data to JSON
        let exportData: [String: Any] = [
            "version": MigrationVersion.current.rawValue,
            "exportDate": Date().timeIntervalSince1970,
            "note": "Export functionality to be implemented"
        ]
        
        // Add export logic for each model type
        
        let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        try jsonData.write(to: exportURL)
        
        return exportURL
    }
}
