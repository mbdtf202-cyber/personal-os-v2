import Foundation
import SwiftData

/// Service for backing up and restoring user data
actor DataBackupService {
    private let modelContainer: ModelContainer
    private let fileManager = FileManager.default
    
    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }
    
    /// Create a complete backup of all user data
    func createBackup() async throws -> URL {
        Logger.log("Creating data backup", category: Logger.general)
        
        let backupURL = try getBackupDirectory()
            .appendingPathComponent("backup_\(Date().timeIntervalSince1970).json")
        
        do {
            // Export all data
            let data = try await exportAllData()
            
            // Write to file
            try data.write(to: backupURL)
            
            Logger.log("Backup created at: \(backupURL.path)", category: Logger.general)
            return backupURL
            
        } catch {
            Logger.error("Backup creation failed: \(error)", category: Logger.general)
            throw BackupError.backupFailed(error)
        }
    }
    
    /// Export all user data to JSON
    func exportAllData() async throws -> Data {
        let context = ModelContext(modelContainer)
        
        var exportData: [String: Any] = [:]
        exportData["version"] = SchemaVersion.current.rawValue
        exportData["exportedAt"] = Date().timeIntervalSince1970
        
        // Export each model type
        // This will be expanded as models are defined
        
        // Example structure:
        // exportData["projects"] = try await exportProjects(context: context)
        // exportData["trades"] = try await exportTrades(context: context)
        // exportData["posts"] = try await exportPosts(context: context)
        // exportData["news"] = try await exportNews(context: context)
        
        return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
    }
    
    /// Import data from backup
    func importData(_ data: Data) async throws {
        Logger.log("Importing data from backup", category: Logger.general)
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw BackupError.invalidBackupFormat
        }
        
        guard let version = json["version"] as? Int else {
            throw BackupError.missingVersion
        }
        
        let context = ModelContext(modelContainer)
        
        // Import each model type
        // This will be expanded as models are defined
        
        // Example:
        // if let projects = json["projects"] as? [[String: Any]] {
        //     try await importProjects(projects, context: context)
        // }
        
        try context.save()
        Logger.log("Data import completed", category: Logger.general)
    }
    
    /// Restore from a backup file
    func restoreFromBackup(url: URL) async throws {
        Logger.log("Restoring from backup: \(url.path)", category: Logger.general)
        
        guard fileManager.fileExists(atPath: url.path) else {
            throw BackupError.backupNotFound
        }
        
        do {
            let data = try Data(contentsOf: url)
            try await importData(data)
            Logger.log("Restore completed successfully", category: Logger.general)
        } catch {
            Logger.error("Restore failed: \(error)", category: Logger.general)
            throw BackupError.restoreFailed(error)
        }
    }
    
    /// Delete all user data (GDPR compliance)
    func deleteAllUserData() async throws {
        Logger.log("Deleting all user data (GDPR compliance)", category: Logger.general)
        
        let context = ModelContext(modelContainer)
        
        // Delete all data from each model type
        // This will be expanded as models are defined
        
        // Example:
        // try await deleteAllProjects(context: context)
        // try await deleteAllTrades(context: context)
        // try await deleteAllPosts(context: context)
        // try await deleteAllNews(context: context)
        
        try context.save()
        
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
        }
        
        // Clear Keychain (will be implemented with SecureStorageService)
        
        Logger.log("All user data deleted", category: Logger.general)
    }
    
    /// Get backup directory
    private func getBackupDirectory() throws -> URL {
        let documentsURL = try fileManager.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        let backupURL = documentsURL.appendingPathComponent("Backups", isDirectory: true)
        
        if !fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.createDirectory(at: backupURL, withIntermediateDirectories: true)
        }
        
        return backupURL
    }
    
    /// List all available backups
    func listBackups() async throws -> [URL] {
        let backupDir = try getBackupDirectory()
        let contents = try fileManager.contentsOfDirectory(
            at: backupDir,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        )
        
        return contents
            .filter { $0.pathExtension == "json" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
    }
    
    /// Delete old backups, keeping only the most recent N
    func cleanupOldBackups(keepRecent: Int = 5) async throws {
        let backups = try await listBackups()
        
        guard backups.count > keepRecent else { return }
        
        let backupsToDelete = backups.dropFirst(keepRecent)
        
        for backup in backupsToDelete {
            try fileManager.removeItem(at: backup)
            Logger.log("Deleted old backup: \(backup.lastPathComponent)", category: Logger.general)
        }
    }
}

/// Backup errors
enum BackupError: Error, LocalizedError {
    case backupFailed(Error)
    case restoreFailed(Error)
    case backupNotFound
    case invalidBackupFormat
    case missingVersion
    
    var errorDescription: String? {
        switch self {
        case .backupFailed(let error):
            return "Backup failed: \(error.localizedDescription)"
        case .restoreFailed(let error):
            return "Restore failed: \(error.localizedDescription)"
        case .backupNotFound:
            return "Backup file not found"
        case .invalidBackupFormat:
            return "Invalid backup file format"
        case .missingVersion:
            return "Backup file missing version information"
        }
    }
}
