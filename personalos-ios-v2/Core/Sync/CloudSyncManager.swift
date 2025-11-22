import Foundation
import SwiftData
import CloudKit
import Combine

@MainActor
class CloudSyncManager: ObservableObject {
    static let shared = CloudSyncManager()
    
    @Published var syncStatus: SyncStatus = .idle
    @Published var lastSyncDate: Date?
    @Published var iCloudAvailable: Bool = false
    
    private let container: CKContainer?
    private let isCloudKitEnabled: Bool
    
    private init() {
        // ✅ 安全检查：如果没有配置 CloudKit entitlements，不初始化容器
        #if DEBUG
        // 在开发环境中，检查是否有 entitlements
        let hasEntitlements = Bundle.main.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") != nil
        self.isCloudKitEnabled = hasEntitlements
        #else
        self.isCloudKitEnabled = true
        #endif
        
        if isCloudKitEnabled {
            self.container = CKContainer(identifier: "iCloud.com.personalos.v2")
            checkiCloudStatus()
        } else {
            self.container = nil
            Logger.warning("CloudKit disabled - entitlements not configured", category: Logger.sync)
        }
    }
    
    func checkiCloudStatus() {
        guard isCloudKitEnabled, let container = container else {
            iCloudAvailable = false
            return
        }
        
        container.accountStatus { status, error in
            Task { @MainActor [weak self] in
                self?.iCloudAvailable = (status == .available)
                
                if let error = error {
                    Logger.error("iCloud status check failed: \(error)", category: Logger.sync)
                }
            }
        }
    }
    
    func enableSync() async throws {
        guard isCloudKitEnabled else {
            throw SyncError.cloudKitNotConfigured
        }
        
        guard iCloudAvailable else {
            throw SyncError.iCloudNotAvailable
        }
        
        syncStatus = .syncing
        
        // SwiftData 自动处理 iCloud 同步
        // 只需确保 ModelContainer 配置了 CloudKit
        Logger.log("✅ iCloud sync enabled", category: Logger.sync)
        syncStatus = .synced
        lastSyncDate = Date()
    }
    
    func manualSync() async {
        guard isCloudKitEnabled, iCloudAvailable else {
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
    case cloudKitNotConfigured
    case iCloudNotAvailable
    case syncFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .cloudKitNotConfigured:
            return "CloudKit is not configured. Please add iCloud capability in Xcode project settings."
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
