import XCTest
@testable import personalos_ios_v2

/// ✅ P2 EXTREME: 测试网络层的 ETag/Last-Modified 智能缓存
final class NetworkCacheValidationTests: XCTestCase {
    
    var mockSession: URLSession!
    var networkClient: NetworkClient!
    
    override func setUp() {
        super.setUp()
        
        // 配置 Mock URLSession
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        mockSession = URLSession(configuration: configuration)
        
        networkClient = NetworkClient(
            config: .default,
            session: mockSession
        )
    }
    
    override func tearDown() {
        MockURLProtocol.requestHandler = nil
        mockSession = nil
        networkClient = nil
        super.tearDown()
    }
    
    func testETagCaching() async throws {
        // Given - 第一次请求返回数据和 ETag
        let testData = TestResponse(message: "Hello", timestamp: Date())
        let etag = "\"abc123\""
        
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            
            if requestCount == 1 {
                // 第一次请求：返回完整数据
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["ETag": etag]
                )!
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try! encoder.encode(testData)
                
                return (response, data)
            } else {
                // 第二次请求：验证是否发送了 If-None-Match
                XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), etag)
                
                // 返回 304 Not Modified
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 304,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                return (response, Data())
            }
        }
        
        // When - 第一次请求
        let result1: TestResponse = try await networkClient.request(
            "https://api.example.com/test",
            cachePolicy: .networkFirst
        )
        
        XCTAssertEqual(result1.message, "Hello")
        XCTAssertEqual(requestCount, 1)
        
        // When - 第二次请求（应该使用 ETag）
        let result2: TestResponse = try await networkClient.request(
            "https://api.example.com/test",
            cachePolicy: .networkFirst
        )
        
        // Then
        XCTAssertEqual(result2.message, "Hello", "Should return cached data on 304")
        XCTAssertEqual(requestCount, 2, "Should have made 2 requests")
    }
    
    func testLastModifiedCaching() async throws {
        // Given
        let testData = TestResponse(message: "World", timestamp: Date())
        let lastModified = "Wed, 21 Oct 2024 07:28:00 GMT"
        
        var requestCount = 0
        
        MockURLProtocol.requestHandler = { request in
            requestCount += 1
            
            if requestCount == 1 {
                // 第一次请求
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["Last-Modified": lastModified]
                )!
                
                let encoder = JSONEncoder()
                encoder.dateEncodingStrategy = .iso8601
                let data = try! encoder.encode(testData)
                
                return (response, data)
            } else {
                // 验证 If-Modified-Since
                XCTAssertEqual(request.value(forHTTPHeaderField: "If-Modified-Since"), lastModified)
                
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 304,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                return (response, Data())
            }
        }
        
        // When
        let result1: TestResponse = try await networkClient.request("https://api.example.com/test2")
        XCTAssertEqual(result1.message, "World")
        
        let result2: TestResponse = try await networkClient.request("https://api.example.com/test2")
        
        // Then
        XCTAssertEqual(result2.message, "World")
        XCTAssertEqual(requestCount, 2)
    }
    
    func testCacheWithoutValidationHeaders() async throws {
        // Given - 服务器不返回 ETag 或 Last-Modified
        let testData = TestResponse(message: "No validation", timestamp: Date())
        
        MockURLProtocol.requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil // 没有缓存验证头
            )!
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try! encoder.encode(testData)
            
            return (response, data)
        }
        
        // When
        let result: TestResponse = try await networkClient.request("https://api.example.com/test3")
        
        // Then - 应该正常工作，只是没有条件请求优化
        XCTAssertEqual(result.message, "No validation")
    }
    
    func testBandwidthSavings() async throws {
        // Given - 模拟大数据响应
        let largeData = String(repeating: "A", count: 10000)
        let testData = TestResponse(message: largeData, timestamp: Date())
        let etag = "\"large-data-v1\""
        
        var totalBytesReceived = 0
        
        MockURLProtocol.requestHandler = { request in
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            
            if request.value(forHTTPHeaderField: "If-None-Match") == etag {
                // 304 响应：几乎没有数据传输
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 304,
                    httpVersion: nil,
                    headerFields: nil
                )!
                
                totalBytesReceived += 0
                return (response, Data())
            } else {
                // 200 响应：完整数据
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: ["ETag": etag]
                )!
                
                let data = try! encoder.encode(testData)
                totalBytesReceived += data.count
                
                return (response, data)
            }
        }
        
        // When
        let _: TestResponse = try await networkClient.request("https://api.example.com/large")
        let bytesFirstRequest = totalBytesReceived
        
        let _: TestResponse = try await networkClient.request("https://api.example.com/large")
        let bytesSecondRequest = totalBytesReceived - bytesFirstRequest
        
        // Then - 第二次请求应该节省大量带宽
        XCTAssertGreaterThan(bytesFirstRequest, 10000, "First request should transfer full data")
        XCTAssertEqual(bytesSecondRequest, 0, "Second request should transfer no data (304)")
    }
}

// MARK: - Test Models

struct TestResponse: Codable {
    let message: String
    let timestamp: Date
}

// MARK: - Mock URL Protocol

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?
    
    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
            fatalError("Request handler not set")
        }
        
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }
    
    override func stopLoading() {
        // No-op
    }
}
