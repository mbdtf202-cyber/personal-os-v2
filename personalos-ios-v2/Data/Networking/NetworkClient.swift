import Foundation
import CryptoKit

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
    static let shared = NetworkClient(config: .default)
    static let news = NetworkClient(config: .news)
    static let stocks = NetworkClient(config: .stocks)
    static let github = NetworkClient(config: .github)
    
    private let session: URLSession
    private let config: NetworkConfig
    private let circuitBreaker: CircuitBreaker
    private let offlineCache: OfflineCache
    
    init(config: NetworkConfig, session: URLSession? = nil) {
        self.config = config
        
        if let providedSession = session {
            self.session = providedSession
        } else {
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
        }
        
        self.circuitBreaker = CircuitBreaker(
            failureThreshold: config.circuitBreakerThreshold,
            timeout: config.circuitBreakerTimeout
        )
        self.offlineCache = OfflineCache()
    }
    
    func request<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod = .get,
        headers: [String: String]? = nil,
        body: Data? = nil,
        cachePolicy: CachePolicy = .networkFirst
    ) async throws -> T {
        
        // 开始性能追踪
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "network_request",
            attributes: [
                "endpoint": endpoint,
                "method": method.rawValue
            ]
        )
        
        defer {
            PerformanceMonitor.shared.stopTrace(traceID)
        }
        
        // Check circuit breaker
        let canAttempt = await MainActor.run { circuitBreaker.canAttempt() }
        guard canAttempt else {
            // Try offline cache
            if let cached: T = offlineCache.get(key: endpoint) {
                PerformanceMonitor.shared.recordCustomMetric(name: "cache_hit", value: 1)
                return cached
            }
            throw AppError.network(.circuitBreakerOpen, retryable: true)
        }
        
        // Try cache first if policy allows
        if cachePolicy == .cacheFirst, let cached: T = offlineCache.get(key: endpoint) {
            PerformanceMonitor.shared.recordCustomMetric(name: "cache_hit", value: 1)
            return cached
        }
        
        // ✅ P2 EXTREME: 获取缓存的 ETag/Last-Modified 用于条件请求
        var conditionalHeaders = headers ?? [:]
        if let cacheValidation = offlineCache.getValidationHeaders(key: endpoint) {
            conditionalHeaders.merge(cacheValidation) { _, new in new }
        }
        
        var lastError: Error?
        
        for attempt in 0..<config.maxRetries {
            do {
                let (result, responseHeaders): (T, [String: String]) = try await performRequestWithHeaders(
                    endpoint,
                    method: method,
                    headers: conditionalHeaders,
                    body: body
                )
                
                await MainActor.run { circuitBreaker.recordSuccess() }
                offlineCache.set(key: endpoint, value: result, headers: responseHeaders)
                
                PerformanceMonitor.shared.recordCustomMetric(name: "network_success", value: 1)
                PerformanceMonitor.shared.recordCustomMetric(name: "retry_count", value: Double(attempt))
                
                return result
            } catch let error as NetworkNotModifiedError {
                // ✅ P2 EXTREME: 304 Not Modified - 使用缓存
                if let cached: T = offlineCache.get(key: endpoint) {
                    PerformanceMonitor.shared.recordCustomMetric(name: "cache_304_hit", value: 1)
                    return cached
                }
                throw error
            } catch {
                lastError = error
                await MainActor.run { circuitBreaker.recordFailure() }
                
                PerformanceMonitor.shared.recordCustomMetric(name: "network_error", value: 1)
                
                // Don't retry on certain errors
                if case AppError.network(.rateLimited, _) = error {
                    PerformanceMonitor.shared.recordCustomMetric(name: "rate_limited", value: 1)
                    throw error
                }
                
                if attempt < config.maxRetries - 1 {
                    let delay = calculateDelay(attempt: attempt)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // Final fallback to cache
        if let cached: T = offlineCache.get(key: endpoint) {
            PerformanceMonitor.shared.recordCustomMetric(name: "cache_fallback", value: 1)
            return cached
        }
        
        throw lastError ?? AppError.network(.noConnection, retryable: true)
    }
    
    private func performRequest<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> T {
        let (result, _): (T, [String: String]) = try await performRequestWithHeaders(
            endpoint,
            method: method,
            headers: headers,
            body: body
        )
        return result
    }
    
    /// ✅ P2 EXTREME: 支持 ETag/Last-Modified 的请求方法
    private func performRequestWithHeaders<T: Codable>(
        _ endpoint: String,
        method: HTTPMethod,
        headers: [String: String]?,
        body: Data?
    ) async throws -> (T, [String: String]) {
        guard let url = URL(string: endpoint) else {
            throw AppError.network(.invalidResponse, retryable: false)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body
        
        headers?.forEach { request.setValue($1, forHTTPHeaderField: $0) }
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse, retryable: true)
        }
        
        // ✅ P2 EXTREME: 处理 304 Not Modified
        if httpResponse.statusCode == 304 {
            throw NetworkNotModifiedError()
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            if httpResponse.statusCode == 429 {
                throw AppError.network(.rateLimited, retryable: true)
            } else if httpResponse.statusCode == 401 {
                throw AppError.network(.unauthorized, retryable: false)
            } else if httpResponse.statusCode == 403 {
                throw AppError.network(.forbidden, retryable: false)
            } else if (500...599).contains(httpResponse.statusCode) {
                throw AppError.network(.serverError(httpResponse.statusCode), retryable: true)
            } else {
                throw AppError.network(.serverError(httpResponse.statusCode), retryable: false)
            }
        }
        
        // 提取响应头
        var responseHeaders: [String: String] = [:]
        if let etag = httpResponse.value(forHTTPHeaderField: "ETag") {
            responseHeaders["ETag"] = etag
        }
        if let lastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified") {
            responseHeaders["Last-Modified"] = lastModified
        }
        
        do {
            // ✅ P0 Fix: 统一日期解码策略为 ISO8601
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(T.self, from: data)
            return (result, responseHeaders)
        } catch {
            throw AppError.network(.invalidResponse, retryable: false)
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

// MARK: - Cache Metadata (must be outside class for Sendable)
struct CacheMetadata: Codable, Sendable {
    let data: Data
    let expirationDate: Date
    let etag: String?
    let lastModified: String?
}

// MARK: - Network Errors
struct NetworkNotModifiedError: Error {}

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
    
    /// ✅ P2 EXTREME: 获取验证头用于条件请求
    func getValidationHeaders(key: String) -> [String: String]? {
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let metadata = try? decoder.decode(CacheMetadata.self, from: data) else {
            return nil
        }
        
        guard metadata.expirationDate > Date() else {
            return nil
        }
        
        var headers: [String: String] = [:]
        if let etag = metadata.etag {
            headers["If-None-Match"] = etag
        }
        if let lastModified = metadata.lastModified {
            headers["If-Modified-Since"] = lastModified
        }
        
        return headers.isEmpty ? nil : headers
    }
    
    func get<T: Codable>(key: String) -> T? {
        // 1. 先查内存缓存
        if let entry = memoryCache.object(forKey: key as NSString) {
            if entry.expirationDate > Date() {
                // ✅ P0 Fix: 统一使用 ISO8601 日期解码策略
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try? decoder.decode(T.self, from: entry.data)
            }
            memoryCache.removeObject(forKey: key as NSString)
        }
        
        // 2. 查磁盘缓存
        let fileURL = cacheDirectory.appendingPathComponent(key.sha256Hash)
        
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        
        // ✅ P0 Fix: 统一使用 ISO8601 日期解码策略
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        guard let metadata = try? decoder.decode(CacheMetadata.self, from: data) else {
            return nil
        }
        
        guard metadata.expirationDate > Date() else {
            try? FileManager.default.removeItem(at: fileURL)
            return nil
        }
        
        // 恢复到内存缓存
        let entry = CacheEntry(data: metadata.data, expirationDate: metadata.expirationDate)
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // ✅ P0 Fix: 解码实际数据时也使用 ISO8601
        return try? decoder.decode(T.self, from: metadata.data)
    }
    
    func set<T: Codable>(key: String, value: T, headers: [String: String] = [:]) {
        // ✅ P0 Fix: 统一使用 ISO8601 日期编码策略
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(value) else { return }
        
        let expirationDate = Date().addingTimeInterval(expirationTime)
        let entry = CacheEntry(data: data, expirationDate: expirationDate)
        
        // 1. 写入内存缓存
        memoryCache.setObject(entry, forKey: key as NSString)
        
        // 2. 异步写入磁盘（包含 ETag/Last-Modified）
        let cacheDir = self.cacheDirectory
        let cacheKey = key.sha256Hash
        Task.detached(priority: .utility) {
            let metadata = CacheMetadata(
                data: data,
                expirationDate: expirationDate,
                etag: headers["ETag"],
                lastModified: headers["Last-Modified"]
            )
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let metadataData = try? encoder.encode(metadata) else { return }
            
            let fileURL = cacheDir.appendingPathComponent(cacheKey)
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
}

// MARK: - NetworkClient Convenience Methods
extension NetworkClient {
    func request<T: Codable>(url: URL) async throws -> T {
        try await request(url.absoluteString)
    }
    
    func requestData(url: URL) async throws -> Data {
        let canAttempt = await MainActor.run { circuitBreaker.canAttempt() }
        guard canAttempt else {
            throw AppError.network(.circuitBreakerOpen, retryable: true)
        }
        
        var request = URLRequest(url: url)
        request.timeoutInterval = config.timeout
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.network(.invalidResponse, retryable: true)
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            await MainActor.run { circuitBreaker.recordFailure() }
            throw AppError.network(.serverError(httpResponse.statusCode), retryable: true)
        }
        
        await MainActor.run { circuitBreaker.recordSuccess() }
        return data
    }
}

nonisolated extension String {
    var sha256Hash: String {
        guard let data = self.data(using: .utf8) else { return self }
        let hash = CryptoKit.SHA256.hash(data: data)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
}
