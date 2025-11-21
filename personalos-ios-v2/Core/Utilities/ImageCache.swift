import SwiftUI

actor ImageCache {
    static let shared = ImageCache()
    
    private var memoryCache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let diskCacheURL: URL
    
    // 🔧 优化: 添加磁盘缓存，避免重复下载
    private init() {
        // 内存缓存配置
        memoryCache.countLimit = 100
        memoryCache.totalCostLimit = 50 * 1024 * 1024 // 50 MB
        
        // 磁盘缓存路径
        let cacheDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)[0]
        diskCacheURL = cacheDirectory.appendingPathComponent("ImageCache", isDirectory: true)
        
        // 创建缓存目录
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    func image(for url: URL) -> UIImage? {
        let key = url.absoluteString as NSString
        
        // 1. 检查内存缓存
        if let cachedImage = memoryCache.object(forKey: key) {
            return cachedImage
        }
        
        // 2. 检查磁盘缓存
        let diskPath = diskCacheURL.appendingPathComponent(url.lastPathComponent)
        if let data = try? Data(contentsOf: diskPath),
           let image = UIImage(data: data) {
            // 加载到内存缓存
            memoryCache.setObject(image, forKey: key)
            return image
        }
        
        return nil
    }
    
    func setImage(_ image: UIImage, for url: URL) {
        let key = url.absoluteString as NSString
        
        // 1. 保存到内存缓存
        memoryCache.setObject(image, forKey: key)
        
        // 2. 保存到磁盘缓存
        let diskPath = diskCacheURL.appendingPathComponent(url.lastPathComponent)
        if let data = image.jpegData(compressionQuality: 0.8) {
            try? data.write(to: diskPath)
        }
    }
    
    func clear() {
        memoryCache.removeAllObjects()
        try? fileManager.removeItem(at: diskCacheURL)
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
    }
    
    func clearMemoryCache() {
        memoryCache.removeAllObjects()
    }
    
    func getDiskCacheSize() -> Int64 {
        guard let enumerator = fileManager.enumerator(at: diskCacheURL, includingPropertiesForKeys: [.fileSizeKey]) else {
            return 0
        }
        
        var totalSize: Int64 = 0
        for case let fileURL as URL in enumerator {
            if let fileSize = try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize {
                totalSize += Int64(fileSize)
            }
        }
        return totalSize
    }
}

struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let url: URL?
    @ViewBuilder let content: (Image) -> Content
    @ViewBuilder let placeholder: () -> Placeholder
    
    @State private var image: UIImage?
    @State private var isLoading = false
    
    var body: some View {
        Group {
            if let image = image {
                content(Image(uiImage: image))
            } else if isLoading {
                placeholder()
            } else {
                placeholder()
                    .task {
                        await loadImage()
                    }
            }
        }
    }
    
    private func loadImage() async {
        guard let url = url else { return }
        
        isLoading = true
        
        // Check cache first
        if let cachedImage = await ImageCache.shared.image(for: url) {
            image = cachedImage
            isLoading = false
            return
        }
        
        // Download image
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let downloadedImage = UIImage(data: data) {
                await ImageCache.shared.setImage(downloadedImage, for: url)
                image = downloadedImage
            }
        } catch {
            Logger.error("Failed to load image: \(error.localizedDescription)", category: Logger.network)
        }
        
        isLoading = false
    }
}
