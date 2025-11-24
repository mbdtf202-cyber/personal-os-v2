import Foundation
import OSLog

/// ✅ MODULARIZATION: 日志系统（从主 App 移动到 Core Package）
public final class Logger {
    public static let shared = Logger()
    
    private let osLog = OSLog(subsystem: "com.personalos.core", category: "general")
    
    private init() {}
    
    public func log(_ message: String, level: OSLogType = .default) {
        os_log(level, log: osLog, "%{public}@", message)
    }
    
    public func debug(_ message: String) {
        log(message, level: .debug)
    }
    
    public func info(_ message: String) {
        log(message, level: .info)
    }
    
    public func error(_ message: String) {
        log(message, level: .error)
    }
}
