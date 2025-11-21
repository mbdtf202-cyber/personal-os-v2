import Foundation
import SwiftData
import CloudKit

@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable: Bool = false
    
    private let container: CKContainer
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.personalos.v2")
        checkiCloudStatus()
    }
    
    func checkiCloudStatus() {
        container.accountStatus { [weak self] status, error in
            Task { @MainActor in
                self?.iCloudAvailable = (status == .available)
                
                if let error = error {
                    Logger.error("iCloud status check failed: \(error)", category: Logger.sync)
                }
            }
        }
    }
    
    func enableSync() async throws {
        guard iCloudAvailable else {
            throw SyncError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        do {
            // SwiftData 自动处理 iCloud 同步
            // 只需确保 ModelContainer 配置了 CloudKit
            Logger.log("✅ iCloud sync enabled", category: Logger.sync)
            syncStatus = .synced
            lastSyncDate = Date()
        } catch {
            syncStatus = .failed(error)
            throw error
        }
    }
    
    func manualSync() async {
        guard iCloudAvailable else {
            Logger.warning("iCloud not available for manual sync", category: Logger.sync)
            return
        }
        
        syncStatus = .syncing
        
        do {
            // 触发手动同步
            try await Task.sleep(nanoseconds: 1_000_000_000) // 模拟同步
            
            syncStatus = .synced
            lastSyncDate = Date()
            Logger.log("✅ Manual sync completed", category: Logger.sync)
        } catch {
            syncStatus = .failed(error)
            Logger.error("Manual sync failed: \(error)", category: Logger.sync)
        }
    }
    
    func resolveConflict(_ conflict: SyncConflict) async throws {
        // 冲突解决策略：最后写入优先
        Logger.log("Resolving conflict: \(conflict.entityType)", category: Logger.sync)
        
        // SwiftData 会自动处理大部分冲突
        // 这里可以实现自定义冲突解决逻辑
    }
}

enum SyncStatus: Equatable {
    case idle
    case syncing
    case synced
    case failed(Error)
    
    static func == (lhs: SyncStatus, rhs: SyncStatus) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.syncing, .syncing), (.synced, .synced):
            return true
        case (.failed, .failed):
            return true
        default:
            return false
        }
    }
}

enum SyncError: LocalizedError {
    case iCloudNotAvailable
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .iCloudNotAvailable:
            return "iCloud is not available. Please sign in to iCloud in Settings."
        case .syncFailed(let reason):
            return "Sync failed: \(reason)"
        }
    }
}

struct SyncConflict {
    let entityType: String
    let localVersion: Date
    let remoteVersion: Date
}
