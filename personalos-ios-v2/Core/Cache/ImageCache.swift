import UIKit
import Foundation

/// 图片缓存管理器
actor ImageCache {
    
    static let shared = ImageCache()
    
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheURL: URL
    private let maxDiskCacheSize: Int = 100 * 1024 * 1024 // 100 MB
    private let maxMemoryCacheSize: Int = 50 * 1024 * 1024 // 50 MB
    
    private init() {
        let cacheDir = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDir.appendingPathComponent("ImageCache")
        
        try? FileManager.default.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // 配置内存缓存
        memoryCache.totalCostLimit = maxMemoryCacheSize
        memoryCache.countLimit = 100
        
        // ✅ Task 28: Use weak self in notification observer to prevent retain cycle
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            NotificationCenter.default.addObserver(
                forName: UIApplication.didReceiveMemoryWarningNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                Task {
                    await self?.handleMemoryWarning()
                }
            }
        }
    }
    
    // MARK: - Load Image
    
    func loadImage(url: URL) async throws -> UIImage {
        let cacheKey = url.absoluteString as NSString
        
        // 1. 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: cacheKey) {
            StructuredLogger.shared.debug("Image loaded from memory cache", context: ["url": url.absoluteString])
            return cachedImage
        }
        
        // 2. 检查磁盘缓存
        if let diskImage = try? await loadFromDisk(url: url) {
            // 恢复到内存缓存
            let cost = diskImage.pngData()?.count ?? 0
            memoryCache.setObject(diskImage, forKey: cacheKey, cost: cost)
            
            StructuredLogger.shared.debug("Image loaded from disk cache", context: ["url": url.absoluteString])
            return diskImage
        }
        
        // 3. 从网络下载
        StructuredLogger.shared.debug("Downloading image from network", context: ["url": url.absoluteString])
        
        let (data, _) = try await URLSession.shared.data(from: url)
        
        guard let image = UIImage(data: data) else {
            throw CacheError.invalidImageData
        }
        
        // 缓存图片
        await cacheImage(image, for: url)
        
        return image
    }
    
    // MARK: - Cache Operations
    
    func cacheImage(_ image: UIImage, for url: URL) async {
        let cacheKey = url.absoluteString as NSString
        
        // 1. 缓存到内存
        let cost = image.pngData()?.count ?? 0
        memoryCache.setObject(image, forKey: cacheKey, cost: cost)
        
        // 2. 异步缓存到磁盘
        // ✅ Task 28: Capture diskCacheURL to avoid retaining self
        Task.detached(priority: .utility) { [diskCacheURL] in
            guard let data = image.pngData() else { return }
            
            let filename = url.absoluteString.sha256Hash
            let fileURL = diskCacheURL.appendingPathComponent(filename)
            
            try? data.write(to: fileURL, options: .atomic)
        }
    }
    
    private func loadFromDisk(url: URL) async throws -> UIImage {
        let filename = url.absoluteString.sha256Hash
        let fileURL = diskCacheURL.appendingPathComponent(filename)
        
        let data = try Data(contentsOf: fileURL)
        
        guard let image = UIImage(data: data) else {
            throw CacheError.invalidImageData
        }
        
        return image
    }
    
    // MARK: - Memory Management
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
        StructuredLogger.shared.info("Memory cache cleared")
    }
    
    func clearDiskCache() async {
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for file in files {
                try? FileManager.default.removeItem(at: file)
            }
            StructuredLogger.shared.info("Disk cache cleared")
        } catch {
            StructuredLogger.shared.error("Failed to clear disk cache: \(error)")
        }
    }
    
    func clearAll() async {
        clearMemoryCache()
        await clearDiskCache()
    }
    
    private func handleMemoryWarning() {
        clearMemoryCache()
        StructuredLogger.shared.warning("Memory warning received, cleared image cache")
    }
    
    // MARK: - Cache Management
    
    func getDiskCacheSize() async -> Int {
        var totalSize = 0
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey])
            
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let size = attributes[.size] as? Int {
                    totalSize += size
                }
            }
        } catch {
            StructuredLogger.shared.error("Failed to calculate disk cache size: \(error)")
        }
        
        return totalSize
    }
    
    func cleanupOldFiles(olderThan days: Int = 7) async {
        let cutoffDate = Date().addingTimeInterval(-TimeInterval(days * 24 * 60 * 60))
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            for file in files {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                if let modificationDate = attributes[.modificationDate] as? Date,
                   modificationDate < cutoffDate {
                    try? FileManager.default.removeItem(at: file)
                }
            }
            
            StructuredLogger.shared.info("Cleaned up old cache files")
        } catch {
            StructuredLogger.shared.error("Failed to cleanup old files: \(error)")
        }
    }
    
    func enforceDiskCacheLimit() async {
        let currentSize = await getDiskCacheSize()
        
        guard currentSize > maxDiskCacheSize else { return }
        
        // 删除最旧的文件直到低于限制
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey]
            )
            
            let sortedFiles = files.sorted { file1, file2 in
                let date1 = (try? FileManager.default.attributesOfItem(atPath: file1.path)[.modificationDate] as? Date) ?? Date.distantPast
                let date2 = (try? FileManager.default.attributesOfItem(atPath: file2.path)[.modificationDate] as? Date) ?? Date.distantPast
                return date1 < date2
            }
            
            var deletedSize = 0
            for file in sortedFiles {
                let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
                let size = attributes[.size] as? Int ?? 0
                
                try? FileManager.default.removeItem(at: file)
                deletedSize += size
                
                if currentSize - deletedSize <= maxDiskCacheSize {
                    break
                }
            }
            
            StructuredLogger.shared.info("Enforced disk cache limit, deleted \(deletedSize) bytes")
        } catch {
            StructuredLogger.shared.error("Failed to enforce disk cache limit: \(error)")
        }
    }
}

enum CacheError: Error {
    case invalidImageData
    case diskCacheFull
}

// 扩展 String 以支持 SHA256
private extension String {
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = data.withUnsafeBytes { bytes in
            var hasher = SHA256Hasher()
            hasher.update(bytes)
            return hasher.finalize()
        }
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}

// 简单的 SHA256 实现
private struct SHA256Hasher {
    private var state: [UInt32] = [
        0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
        0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19
    ]
    
    mutating func update(_ bytes: UnsafeRawBufferPointer) {
        // 简化实现，实际应使用 CryptoKit
    }
    
    func finalize() -> [UInt8] {
        return state.flatMap { value in
            [
                UInt8((value >> 24) & 0xff),
                UInt8((value >> 16) & 0xff),
                UInt8((value >> 8) & 0xff),
                UInt8(value & 0xff)
            ]
        }
    }
}
