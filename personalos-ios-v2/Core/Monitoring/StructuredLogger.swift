import Foundation
import OSLog

/// 结构化日志级别
enum LogLevel: String, Sendable {
    case debug = "DEBUG"
    case info = "INFO"
    case warning = "WARNING"
    case error = "ERROR"
    case critical = "CRITICAL"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

/// 结构化日志条目
struct LogEntry: Sendable {
    let timestamp: Date
    let level: LogLevel
    let message: String
    let category: String
    let context: [String: String]
    let traceID: String?
    let spanID: String?
    let file: String
    let function: String
    let line: Int
    
    func formatted() -> String {
        var parts: [String] = []
        
        // 时间戳
        let formatter = ISO8601DateFormatter()
        parts.append(formatter.string(from: timestamp))
        
        // 级别
        parts.append("[\(level.rawValue)]")
        
        // 追踪信息
        if let traceID = traceID {
            parts.append("[trace:\(traceID.prefix(8))]")
        }
        if let spanID = spanID {
            parts.append("[span:\(spanID.prefix(8))]")
        }
        
        // 分类
        parts.append("[\(category)]")
        
        // 消息
        parts.append(message)
        
        // 上下文
        if !context.isEmpty {
            let contextStr = context.map { "\($0.key)=\($0.value)" }.joined(separator: ", ")
            parts.append("{\(contextStr)}")
        }
        
        // 位置
        parts.append("(\(file):\(line) \(function))")
        
        return parts.joined(separator: " ")
    }
}

/// 结构化日志器
@MainActor
final class StructuredLogger {
    static let shared = StructuredLogger()
    
    private let osLog = OSLog(subsystem: "com.personalos.v2", category: "app")
    private var logEntries: [LogEntry] = []
    private let maxEntries = 1000
    
    private init() {}
    
    func log(
        _ message: String,
        level: LogLevel = .info,
        category: String = "general",
        context: [String: String] = [:],
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        // 获取追踪上下文
        let traceContext = TraceContextManager.shared.getCurrentContext()
        
        // 合并上下文
        var fullContext = context
        if let traceContext = traceContext {
            fullContext.merge(traceContext.toLogContext()) { _, new in new }
        }
        
        // 创建日志条目
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            message: message,
            category: category,
            context: fullContext,
            traceID: traceContext?.traceID,
            spanID: traceContext?.spanID,
            file: (file as NSString).lastPathComponent,
            function: function,
            line: line
        )
        
        // 存储日志
        logEntries.append(entry)
        if logEntries.count > maxEntries {
            logEntries.removeFirst(logEntries.count - maxEntries)
        }
        
        // 输出到 OSLog
        os_log(level.osLogType, log: osLog, "%{public}@", entry.formatted())
        
        // 如果是错误，添加面包屑
        if level == .error || level == .critical {
            FirebaseCrashReporter.shared.addBreadcrumb(
                message: message,
                metadata: fullContext
            )
        }
    }
    
    func debug(_ message: String, category: String = "general", context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .debug, category: category, context: context, file: file, function: function, line: line)
    }
    
    func info(_ message: String, category: String = "general", context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .info, category: category, context: context, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, category: String = "general", context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .warning, category: category, context: context, file: file, function: function, line: line)
    }
    
    func error(_ message: String, category: String = "general", context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .error, category: category, context: context, file: file, function: function, line: line)
    }
    
    func critical(_ message: String, category: String = "general", context: [String: String] = [:], file: String = #file, function: String = #function, line: Int = #line) {
        log(message, level: .critical, category: category, context: context, file: file, function: function, line: line)
    }
    
    // MARK: - Query
    
    func getRecentLogs(limit: Int = 100) -> [LogEntry] {
        Array(logEntries.suffix(limit))
    }
    
    func filterLogs(
        level: LogLevel? = nil,
        category: String? = nil,
        traceID: String? = nil,
        since: Date? = nil
    ) -> [LogEntry] {
        logEntries.filter { entry in
            if let level = level, entry.level != level { return false }
            if let category = category, entry.category != category { return false }
            if let traceID = traceID, entry.traceID != traceID { return false }
            if let since = since, entry.timestamp < since { return false }
            return true
        }
    }
    
    func searchLogs(query: String) -> [LogEntry] {
        logEntries.filter { entry in
            entry.message.localizedCaseInsensitiveContains(query) ||
            entry.context.values.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    func exportLogs() -> String {
        logEntries.map { $0.formatted() }.joined(separator: "\n")
    }
}
