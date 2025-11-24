import Foundation

/// ✅ MODULARIZATION: 网络客户端（从主 App 移动到 Core Package）
/// 这是一个占位符，实际实现需要从主 App 迁移过来

public protocol NetworkClientProtocol {
    func request<T: Codable>(_ endpoint: String) async throws -> T
}

public final class NetworkClient: NetworkClientProtocol {
    public static let shared = NetworkClient()
    
    private init() {}
    
    public func request<T: Codable>(_ endpoint: String) async throws -> T {
        // 实现将从主 App 迁移
        fatalError("To be implemented")
    }
}
