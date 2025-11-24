import Foundation

/// 通用缓存管理器
actor CacheManager<Key: Hashable & Sendable, Value: Sendable> {
    
    private struct CacheEntry {
        let value: Value
        let expirationDate: Date
        let accessCount: Int
        let lastAccessDate: Date
    }
    
    private var cache: [Key: CacheEntry] = [:]
    private let maxSize: Int
    private let defaultTTL: TimeInterval
    
    init(maxSize: Int = 100, defaultTTL: TimeInterval = 3600) {
        self.maxSize = maxSize
        self.defaultTTL = defaultTTL
    }
    
    // MARK: - Basic Operations
    
    func get(_ key: Key) -> Value? {
        guard let entry = cache[key] else {
            return nil
        }
        
        // 检查是否过期
        if entry.expirationDate < Date() {
            cache.removeValue(forKey: key)
            return nil
        }
        
        // 更新访问信息 (LRU)
        cache[key] = CacheEntry(
            value: entry.value,
            expirationDate: entry.expirationDate,
            accessCount: entry.accessCount + 1,
            lastAccessDate: Date()
        )
        
        return entry.value
    }
    
    func set(_ key: Key, value: Value, ttl: TimeInterval? = nil) {
        let expirationDate = Date().addingTimeInterval(ttl ?? defaultTTL)
        
        let entry = CacheEntry(
            value: value,
            expirationDate: expirationDate,
            accessCount: 1,
            lastAccessDate: Date()
        )
        
        cache[key] = entry
        
        // 如果超过最大大小，执行 LRU 淘汰
        if cache.count > maxSize {
            evictLRU()
        }
    }
    
    func remove(_ key: Key) {
        cache.removeValue(forKey: key)
    }
    
    func clear() {
        cache.removeAll()
    }
    
    // MARK: - LRU Eviction
    
    private func evictLRU() {
        // 找到最少使用的条目
        let sortedEntries = cache.sorted { lhs, rhs in
            let lhsEntry = lhs.value
            let rhsEntry = rhs.value
            
            // 优先淘汰访问次数少的
            if lhsEntry.accessCount != rhsEntry.accessCount {
                return lhsEntry.accessCount < rhsEntry.accessCount
            }
            
            // 其次淘汰最久未访问的
            return lhsEntry.lastAccessDate < rhsEntry.lastAccessDate
        }
        
        // 淘汰 10% 的条目
        let evictionCount = max(1, maxSize / 10)
        for (key, _) in sortedEntries.prefix(evictionCount) {
            cache.removeValue(forKey: key)
        }
    }
    
    // MARK: - Cleanup
    
    func removeExpired() {
        let now = Date()
        let expiredKeys = cache.filter { $0.value.expirationDate < now }.map { $0.key }
        expiredKeys.forEach { cache.removeValue(forKey: $0) }
    }
    
    // MARK: - Statistics
    
    func getStats() -> CacheStats {
        let now = Date()
        let validCount = cache.filter { $0.value.expirationDate >= now }.count
        let expiredCount = cache.count - validCount
        
        return CacheStats(
            totalEntries: cache.count,
            validEntries: validCount,
            expiredEntries: expiredCount,
            maxSize: maxSize
        )
    }
}

struct CacheStats: Sendable {
    let totalEntries: Int
    let validEntries: Int
    let expiredEntries: Int
    let maxSize: Int
    
    var utilizationPercentage: Double {
        guard maxSize > 0 else { return 0 }
        return Double(validEntries) / Double(maxSize) * 100
    }
}
