import Foundation
import CryptoKit

enum NetworkError: Error {
    case invalidURL
    case noData
    case decodingError
    case serverError(Int)
    case timeout
    case circuitBreakerOpen
    case rateLimited
}

struct NetworkConfig {
    var timeout: TimeInterval
    var maxRetries: Int
    var retryDelay: TimeInterval
    var useExponentialBackoff: Bool
    var circuitBreakerThreshold: Int
    var circuitBreakerTimeout: TimeInterval
    
    static let `default` = NetworkConfig(
        timeout: 30,
        maxRetries: 3,
        retryDelay: 1.0,
        useExponentialBackoff: true,
        circuitBreakerThreshold: 5,
        circuitBreakerTimeout: 60
    )
    
    static let news = NetworkConfig(
        timeout: 15,
        maxRetries: 2,
        retryDelay: 0.5,
        useExponentialBackoff: true,
        circuitBreakerThreshold: 3,
        circuitBreakerTimeout: 30
    )
    
    static let stocks = NetworkConfig(
        timeout: 10,
        maxRetries: 3,
        retryDelay: 0.3,
        useExponentialBackoff: true,
        circuitBreakerThreshold: 5,
        circuitBreakerTimeout: 45
    )
    
    static let github = NetworkConfig(
        timeout: 20,
        maxRetries: 2,
        retryDelay: 1.0,
        useExponentialBackoff: true,
        circuitBreakerThreshold: 3,
        circuitBreakerTimeout: 60
    )
}

class NetworkClient {
    private let session: URLSession
    private let config: NetworkConfig
    private var circuitBreaker: CircuitBreaker
    private let offlineCache: OfflineCache
    
    init(config: NetworkConfig) {
        self.config = config
        
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = config.timeout
        configuration.timeoutIntervalForResource = config.timeout * 2
        configuration.waitsForConnectivity = true
        
        // ✅ 集成 SSL Pinning
        self.session = URLSession(
            configuration: configuration,
            delegate: SSLPinningManager.shared,
            delegateQueue: nil
        )
        
        self.circuitBreaker = CircuitBreaker(
            threshold: config.circuitBreakerThreshold,
            timeout: config.circuitBreakerTimeout
        )
        self.offlineCache = OfflineCache()
    }
    
    @MainActor
    func request<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        cachePolicy: CachePolicy = .networkFirst
    ) async throws -> T {
        
        // Check circuit breaker
        guard !circuitBreaker.isOpen else {
            // Try offline cache
            if let cached: T = offlineCache.get(key: endpoint) {
                return cached
            }
            throw NetworkError.circuitBreakerOpen
        }
        
        // Try cache first if policy allows
        if cachePolicy == .cacheFirst, let cached: T = offlineCache.get(key: endpoint) {
            return cached
        }
        
        var lastError: Error?
        
        for attempt in 0..<config.maxRetries {
            do {
                let result: T = try await performRequest(
                    endpoint,
                    method: method,
                    headers: headers,
                    body: body
                )
                
                circuitBreaker.recordSuccess()
                offlineCache.set(key: endpoint, value: result)
                
                return result
            } catch {
                lastError = error
                circuitBreaker.recordFailure()
                
                // Don't retry on certain errors
                if case NetworkError.serverError(let code) = error, code == 429 {
                    throw NetworkError.rateLimited
                }
                
                if attempt < config.maxRetries - 1 {
                    let delay = calculateDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // Final fallback to cache
        if let cached: T = offlineCache.get(key: endpoint) {
            return cached
        }
        
        throw lastError ?? NetworkError.noData
    }
    
    private func performRequest<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> T {
        guard let url = URL(string: endpoint) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw NetworkError.decodingError
        }
    }
    
    private func calculateDelay(attempt: Int) -> TimeInterval {
        if config.useExponentialBackoff {
            return config.retryDelay * pow(2.0, Double(attempt))
        }
        return config.retryDelay
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
}

enum CachePolicy {
    case networkFirst
    case cacheFirst
    case networkOnly
}

// MARK: - Circuit Breaker
class CircuitBreaker {
    private var failureCount = 0
    private var lastFailureTime: Date?
    private let threshold: Int
    private let timeout: TimeInterval
    
    var isOpen: Bool {
        guard failureCount >= threshold else { return false }
        guard let lastFailure = lastFailureTime else { return false }
        
        return Date().timeIntervalSince(lastFailure) < timeout
    }
    
    init(threshold: Int, timeout: TimeInterval) {
        self.threshold = threshold
        self.timeout = timeout
    }
    
    func recordSuccess() {
        failureCount = 0
        lastFailureTime = nil
    }
    
    func recordFailure() {
        failureCount += 1
        lastFailureTime = Date()
    }
}

// MARK: - Offline Cache (Disk-based)
class OfflineCache {
    private let memoryCache = NSCache<NSString, CacheEntry>()
    private let expirationTime: TimeInterval = 3600 // 1 hour
    private let cacheDirectory: URL
    
    init() {
        // ✅ P0 Fix: 使用磁盘缓存，而非仅内存
        let paths = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("OfflineCache")
        
        try? FileManager.default.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    func get<T: Codable>(key: String) -> T? {
        // 1. 先查内存缓存
        if let entry = memoryCache.object(forKey: key as NSString) {
            if entry.expirationDate > Date() {
                return try? JSONDecoder().decode(T.self, from: entry.data)
            }
            memoryCache.removeObject(forKey: key as NSString)
        }
        
        // 2. 查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        
        guard let data = try? Data(contentsOf: fileURL),
              let metadata = try? JSONDecoder().decode(CacheMetadata.self, from: data) else {
            return nil
        }
        
        guard metadata.expirationDate > Date() else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        
        // 恢复到内存缓存
        let entry = CacheEntry(data: metadata.data, expirationDate: metadata.expirationDate)
        memoryCache.setObject(entry, forKey: key as NSString)
        
        return try? JSONDecoder().decode(T.self, from: metadata.data)
    }
    
    func set<T: Codable>(key: String, value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        
        let expirationDate = Date().addingTimeInterval(expirationTime)
        let entry = CacheEntry(data: data, expirationDate: expirationDate)
        
        // 1. 写入内存缓存
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // 2. 异步写入磁盘
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            
            let metadata = CacheMetadata(data: data, expirationDate: expirationDate)
            guard let metadataData = try? JSONEncoder().encode(metadata) else { return }
            
            let fileURL = self.cacheDirectory.appendingPathComponent(key.sha256Hash)
            try? metadataData.write(to: fileURL, options: .atomic)
        }
    }
    
    private class CacheEntry {
        let data: Data
        let expirationDate: Date
        
        init(data: Data, expirationDate: Date) {
            self.data = data
            self.expirationDate = expirationDate
        }
    }
    
    struct CacheMetadata: Codable {
        let data: Data
        let expirationDate: Date
    }
}

nonisolated extension String {
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = CryptoKit.SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}

    // MARK: - Convenience Methods
    func request<T: Codable>(url: URL) async throws -> T {
        try await request(url.absoluteString)
    }
    
    func requestData(url: URL) async throws -> Data {
        guard !circuitBreaker.isOpen else {
            throw NetworkError.circuitBreakerOpen
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = config.timeout
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.noData
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            circuitBreaker.recordFailure()
            throw NetworkError.serverError(httpResponse.statusCode)
        }
        
        circuitBreaker.recordSuccess()
        return data
    }
