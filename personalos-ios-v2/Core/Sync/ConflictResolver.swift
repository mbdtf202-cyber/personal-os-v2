import Foundation
import SwiftData

/// ✅ EXTREME FIX 4: CRDT-inspired conflict resolution for multi-device sync
/// Implements vector clocks and device tracking for eventual consistency

// MARK: - Conflict Resolution Strategy

enum ConflictResolutionStrategy {
    case lastWriteWins          // 最后写入优先（默认）
    case vectorClock            // 向量时钟（CRDT-inspired）
    case manual                 // 手动解决
    case merge                  // 智能合并
}

// MARK: - Syncable Protocol

protocol Syncable {
    var id: String { get }
    var lastModified: Date { get set }
    var deviceID: String { get set }
    var vectorClock: [String: Int] { get set }
}

// MARK: - Conflict Resolver

@MainActor
final class ConflictResolver {
    static let shared = ConflictResolver()
    
    private let deviceID: String
    private var strategy: ConflictResolutionStrategy = .vectorClock
    
    private init() {
        // 生成或恢复设备唯一标识
        if let saved = UserDefaults.standard.string(forKey: "device_id") {
            self.deviceID = saved
        } else {
            self.deviceID = UUID().uuidString
            UserDefaults.standard.set(self.deviceID, forKey: "device_id")
        }
        
        Logger.log("🔧 ConflictResolver initialized with deviceID: \(deviceID)", category: Logger.sync)
    }
    
    // MARK: - Vector Clock Operations
    
    /// 增加本地向量时钟
    func incrementVectorClock<T: Syncable>(_ item: inout T) {
        var clock = item.vectorClock
        clock[deviceID, default: 0] += 1
        item.vectorClock = clock
        item.deviceID = deviceID
        item.lastModified = Date()
        
        Logger.log("📊 Vector clock incremented: \(clock)", category: Logger.sync)
    }
    
    /// 比较两个向量时钟
    func compareVectorClocks(_ clock1: [String: Int], _ clock2: [String: Int]) -> ClockComparison {
        var clock1Greater = false
        var clock2Greater = false
        
        // 获取所有设备 ID
        let allDevices = Set(clock1.keys).union(clock2.keys)
        
        for device in allDevices {
            let v1 = clock1[device, default: 0]
            let v2 = clock2[device, default: 0]
            
            if v1 > v2 {
                clock1Greater = true
            } else if v2 > v1 {
                clock2Greater = true
            }
        }
        
        if clock1Greater && !clock2Greater {
            return .after  // clock1 更新
        } else if clock2Greater && !clock1Greater {
            return .before // clock2 更新
        } else if clock1Greater && clock2Greater {
            return .concurrent // 并发修改
        } else {
            return .equal // 相同
        }
    }
    
    // MARK: - Conflict Resolution
    
    /// 解决两个版本之间的冲突
    func resolve<T: Syncable>(local: T, remote: T) -> ConflictResolution<T> {
        switch strategy {
        case .lastWriteWins:
            return resolveLastWriteWins(local: local, remote: remote)
            
        case .vectorClock:
            return resolveVectorClock(local: local, remote: remote)
            
        case .manual:
            return .needsManualResolution(local: local, remote: remote)
            
        case .merge:
            return resolveMerge(local: local, remote: remote)
        }
    }
    
    private func resolveLastWriteWins<T: Syncable>(local: T, remote: T) -> ConflictResolution<T> {
        if local.lastModified > remote.lastModified {
            Logger.log("✅ Conflict resolved: Local wins (newer)", category: Logger.sync)
            return .useLocal
        } else {
            Logger.log("✅ Conflict resolved: Remote wins (newer)", category: Logger.sync)
            return .useRemote
        }
    }
    
    private func resolveVectorClock<T: Syncable>(local: T, remote: T) -> ConflictResolution<T> {
        let comparison = compareVectorClocks(local.vectorClock, remote.vectorClock)
        
        switch comparison {
        case .after:
            Logger.log("✅ Conflict resolved: Local is newer (vector clock)", category: Logger.sync)
            return .useLocal
            
        case .before:
            Logger.log("✅ Conflict resolved: Remote is newer (vector clock)", category: Logger.sync)
            return .useRemote
            
        case .concurrent:
            Logger.warning("⚠️ Concurrent modification detected, falling back to last-write-wins", category: Logger.sync)
            return resolveLastWriteWins(local: local, remote: remote)
            
        case .equal:
            Logger.log("✅ No conflict: Versions are equal", category: Logger.sync)
            return .useLocal
        }
    }
    
    private func resolveMerge<T: Syncable>(local: T, remote: T) -> ConflictResolution<T> {
        // 智能合并策略（需要根据具体模型实现）
        // 这里先使用向量时钟策略
        return resolveVectorClock(local: local, remote: remote)
    }
    
    // MARK: - Merge Vector Clocks
    
    /// 合并两个向量时钟（取最大值）
    func mergeVectorClocks(_ clock1: [String: Int], _ clock2: [String: Int]) -> [String: Int] {
        var merged = clock1
        
        for (device, version) in clock2 {
            merged[device] = max(merged[device, default: 0], version)
        }
        
        return merged
    }
    
    // MARK: - Configuration
    
    func setStrategy(_ strategy: ConflictResolutionStrategy) {
        self.strategy = strategy
        Logger.log("🔧 Conflict resolution strategy set to: \(strategy)", category: Logger.sync)
    }
}

// MARK: - Supporting Types

enum ClockComparison {
    case before     // clock1 < clock2
    case after      // clock1 > clock2
    case concurrent // 并发修改
    case equal      // 相同
}

enum ConflictResolution<T> {
    case useLocal
    case useRemote
    case merged(T)
    case needsManualResolution(local: T, remote: T)
}

// MARK: - Syncable Extensions

extension Syncable {
    mutating func prepareForSync() {
        ConflictResolver.shared.incrementVectorClock(&self)
    }
}
