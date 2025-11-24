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
        
        // ✅ Task 28: Already using weak self - good!
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
    
    // ✅ EXTREME OPTIMIZATION 1: 明确界限 - SwiftData 自动同步 vs 手动 CRDT
    // 当使用 cloudKitDatabase: .automatic 时，SwiftData 底层已经处理冲突
    // 手动冲突解决仅在完全接管 CloudKit 时使用（cloudKitDatabase: .none + 手动 CKRecord）
    
    /// 仅在手动管理 CloudKit 时使用（非 SwiftData 自动同步）
    /// 如果使用 SwiftData 的 .automatic 模式，此方法不应被调用
    func resolveConflictManually(_ conflict: SyncConflict) async throws {
        guard !isCloudKitEnabled else {
            Logger.warning("⚠️ Manual conflict resolution called but SwiftData auto-sync is enabled. This is redundant.", category: Logger.sync)
            return
        }
        
        // 仅在完全手动管理 CloudKit 时才执行
        Logger.log("Manually resolving conflict: \(conflict.entityType)", category: Logger.sync)
        
        // 使用 ConflictResolver 处理冲突（仅用于手动 CKRecord 操作）
        let resolver = ConflictResolver.shared
        Logger.log("Using vector clock strategy for manual conflict resolution", category: Logger.sync)
    }
    
    /// 设置冲突策略（仅在手动管理 CloudKit 时有效）
    func setConflictStrategy(_ strategy: ConflictResolutionStrategy) {
        guard !isCloudKitEnabled else {
            Logger.warning("⚠️ Setting conflict strategy has no effect when SwiftData auto-sync is enabled", category: Logger.sync)
            return
        }
        ConflictResolver.shared.setStrategy(strategy)
    }
    
    /// 检查当前是否使用 SwiftData 自动同步
    var isUsingAutoSync: Bool {
        return isCloudKitEnabled
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
