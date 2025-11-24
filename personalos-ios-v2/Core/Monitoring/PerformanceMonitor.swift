import Foundation
import OSLog

@MainActor
class PerformanceMonitor {
    static let shared = PerformanceMonitor()
    
    private let logger = OSLog(subsystem: "com.personalos.v2", category: "performance")
    private var metrics: [PerformanceMetric] = []
    private var customMetrics: [String: [Double]] = [:]
    private var activeTraces: [String: TraceInfo] = [:]
    
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
    
    // MARK: - Enhanced Tracing
    // ✅ FINAL OPTIMIZATION 3: Release 模式彻底移除追踪开销
    
    func startTrace(name: String, attributes: [String: String] = [:]) -> String {
        #if DEBUG || TESTFLIGHT
        let traceID = UUID().uuidString
        let trace = TraceInfo(
            id: traceID,
            name: name,
            startTime: Date(),
            attributes: attributes
        )
        activeTraces[traceID] = trace
        
        Logger.log("Started trace: \(name) [\(traceID)]", category: Logger.performance)
        return traceID
        #else
        // Release 模式：返回空字符串，不创建追踪对象
        return ""
        #endif
    }
    
    func stopTrace(_ traceID: String, metrics: [String: Double] = [:]) {
        #if DEBUG || TESTFLIGHT
        guard let trace = activeTraces.removeValue(forKey: traceID) else {
            Logger.warning("Attempted to stop unknown trace: \(traceID)", category: Logger.performance)
            return
        }
        
        let duration = Date().timeIntervalSince(trace.startTime)
        
        // 记录追踪
        let metric = PerformanceMetric(
            timestamp: trace.startTime,
            operation: trace.name,
            duration: duration,
            attributes: trace.attributes,
            customMetrics: metrics
        )
        
        self.metrics.append(metric)
        
        // 记录自定义指标
        for (key, value) in metrics {
            recordCustomMetric(name: key, value: value)
        }
        
        Logger.log("Stopped trace: \(trace.name) - Duration: \(duration)s", category: Logger.performance)
        
        // 上报到分析系统
        AnalyticsLogger.shared.log(.performance(metric: trace.name, duration: duration))
        #else
        // Release 模式：完全跳过，零开销
        return
        #endif
    }
    
    func recordCustomMetric(name: String, value: Double) {
        #if DEBUG || TESTFLIGHT
        if customMetrics[name] == nil {
            customMetrics[name] = []
        }
        customMetrics[name]?.append(value)
        
        Logger.log("Custom metric: \(name) = \(value)", category: Logger.performance)
        #else
        // Release 模式：仅记录到 OSLog，不存储在内存
        os_log(.debug, log: logger, "Metric: %{public}@ = %.2f", name, value)
        #endif
    }
    
    func incrementCounter(name: String, by value: Int = 1) {
        #if DEBUG || TESTFLIGHT
        let currentValue = (customMetrics[name]?.last ?? 0) + Double(value)
        recordCustomMetric(name: name, value: currentValue)
        #else
        // Release 模式：轻量级计数，不存储历史
        os_log(.debug, log: logger, "Counter: %{public}@ += %d", name, value)
        #endif
    }
    
    private func recordMetric(operation: String, duration: TimeInterval, attributes: [String: String] = [:]) {
        let metric = PerformanceMetric(
            timestamp: Date(),
            operation: operation,
            duration: duration,
            attributes: attributes
        )
        
        metrics.append(metric)
        
        let level: OSLogType = duration > 1.0 ? .error : (duration > 0.5 ? .default : .debug)
        os_log(level, log: logger, "⏱️ %{public}@ took %.3f seconds", operation, duration)
        
        // 记录到分析系统
        AnalyticsLogger.shared.log(.performance(metric: operation, duration: duration))
        
        // 如果性能过慢，记录警告
        if duration > 2.0 {
            Logger.warning("Slow operation detected: \(operation) took \(duration)s", category: Logger.performance)
            FirebaseCrashReporter.shared.addBreadcrumb(
                message: "Slow operation: \(operation)",
                metadata: ["duration": duration]
            )
        }
    }
    
    func getMetrics(for operation: String? = nil) -> [PerformanceMetric] {
        #if DEBUG || TESTFLIGHT
        if let operation = operation {
            return metrics.filter { $0.operation == operation }
        }
        return metrics
        #else
        // Release 模式：不提供历史指标查询
        return []
        #endif
    }
    
    func getAverageTime(for operation: String) -> TimeInterval? {
        #if DEBUG || TESTFLIGHT
        let filtered = metrics.filter { $0.operation == operation }
        guard !filtered.isEmpty else { return nil }
        return filtered.map(\.duration).reduce(0, +) / Double(filtered.count)
        #else
        return nil
        #endif
    }
    
    func getCustomMetricStats(for name: String) -> MetricStats? {
        #if DEBUG || TESTFLIGHT
        guard let values = customMetrics[name], !values.isEmpty else { return nil }
        
        let sorted = values.sorted()
        let count = values.count
        let sum = values.reduce(0, +)
        
        return MetricStats(
            count: count,
            sum: sum,
            average: sum / Double(count),
            min: sorted.first ?? 0,
            max: sorted.last ?? 0,
            median: sorted[count / 2]
        )
        #else
        return nil
        #endif
    }
}

struct TraceInfo {
    let id: String
    let name: String
    let startTime: Date
    let attributes: [String: String]
}

struct MetricStats {
    let count: Int
    let sum: Double
    let average: Double
    let min: Double
    let max: Double
    let median: Double
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
    var attributes: [String: String] = [:]
    var customMetrics: [String: Double] = [:]
}
