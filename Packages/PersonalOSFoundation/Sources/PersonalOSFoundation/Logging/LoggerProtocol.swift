import Foundation

/// 日志协议 - 零依赖的基础接口
/// 所有模块都可以依赖此协议，而不需要依赖具体实现
public protocol LoggerProtocol {
    func log(_ message: String, level: LogLevel, category: String)
    func debug(_ message: String, category: String)
    func info(_ message: String, category: String)
    func warning(_ message: String, category: String)
    func error(_ message: String, category: String)
}

public enum LogLevel: String, Codable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
}

/// 默认的空实现（用于测试或不需要日志的场景）
public struct NoOpLogger: LoggerProtocol {
    public init() {}
    
    public func log(_ message: String, level: LogLevel, category: String) {}
    public func debug(_ message: String, category: String) {}
    public func info(_ message: String, category: String) {}
    public func warning(_ message: String, category: String) {}
    public func error(_ message: String, category: String) {}
}
