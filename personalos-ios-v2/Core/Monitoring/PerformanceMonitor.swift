import Foundation
import OSLog

@MainActor
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = OSLog(subsystem: "com.personalos.v2", category: "performance")
    private var metrics: [PerformanceMetric] = []
    
    private init() {}
    
    func measure<T>(_ operation: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()
        
        defer {
            let duration = CFAbsoluteTimeGetCurrent() - start
            recordMetric(operation: operation, duration: duration)
        }
        
        return try await block()
    }
    
    func startMeasuring(_ operation: String) -> PerformanceToken {
        PerformanceToken(operation: operation, startTime: CFAbsoluteTimeGetCurrent())
    }
    
    func endMeasuring(_ token: PerformanceToken) {
        let duration = CFAbsoluteTimeGetCurrent() - token.startTime
        recordMetric(operation: token.operation, duration: duration)
    }
    
    private func recordMetric(operation: String, duration: TimeInterval) {
        let metric = PerformanceMetric(
            timestamp: Date(),
            operation: operation,
            duration: duration
        )
        
        metrics.append(metric)
        
        let level: OSLogType = duration > 1.0 ? .error : (duration > 0.5 ? .default : .debug)
        os_log(level, log: logger, "⏱️ %{public}@ took %.3f seconds", operation, duration)
        
        // 记录到分析系统
        AnalyticsLogger.shared.log(.performance(metric: operation, duration: duration))
        
        // 如果性能过慢，记录警告
        if duration > 2.0 {
            Logger.warning("Slow operation detected: \(operation) took \(duration)s", category: Logger.performance)
        }
    }
    
    func getMetrics(for operation: String? = nil) -> [PerformanceMetric] {
        if let operation = operation {
            return metrics.filter { $0.operation == operation }
        }
        return metrics
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        let filtered = metrics.filter { $0.operation == operation }
        guard !filtered.isEmpty else { return nil }
        return filtered.map(\.duration).reduce(0, +) / Double(filtered.count)
    }
}

struct PerformanceToken {
    let operation: String
    let startTime: CFAbsoluteTime
}

struct PerformanceMetric: Identifiable {
    let id = UUID()
    let timestamp: Date
    let operation: String
    let duration: TimeInterval
}
