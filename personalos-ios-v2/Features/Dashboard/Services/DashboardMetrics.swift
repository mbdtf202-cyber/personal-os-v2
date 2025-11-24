import Foundation

/// Dashboard 性能指标收集器
@MainActor
final class DashboardMetrics {
    static let shared = DashboardMetrics()
    
    private var firstScreenLoadStart: Date?
    private var operationSuccessCount: [String: Int] = [:]
    private var operationFailureCount: [String: Int] = [:]
    
    private init() {}
    
    // MARK: - 首屏加载时间
    
    func startFirstScreenLoad() {
        firstScreenLoadStart = Date()
        StructuredLogger.shared.debug("Dashboard first screen load started", category: "metrics")
    }
    
    func endFirstScreenLoad() {
        guard let start = firstScreenLoadStart else { return }
        
        let duration = Date().timeIntervalSince(start)
        
        PerformanceMonitor.shared.recordCustomMetric(
            name: "dashboard_first_screen_load_time",
            value: duration
        )
        
        StructuredLogger.shared.info(
            "Dashboard first screen loaded",
            category: "metrics",
            context: ["duration": String(format: "%.3f", duration)]
        )
        
        // 如果加载时间过长，记录警告
        if duration > 2.0 {
            StructuredLogger.shared.warning(
                "Slow dashboard load detected",
                category: "metrics",
                context: ["duration": String(format: "%.3f", duration)]
            )
        }
        
        firstScreenLoadStart = nil
    }
    
    // MARK: - Health 同步耗时
    
    func measureHealthSync(_ operation: () async -> Void) async {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "dashboard_health_sync",
            attributes: ["operation": "sync"]
        )
        
        let start = Date()
        
        await operation()
        
        let duration = Date().timeIntervalSince(start)
        
        PerformanceMonitor.shared.stopTrace(traceID, metrics: [
            "duration": duration
        ])
        
        PerformanceMonitor.shared.recordCustomMetric(
            name: "health_sync_duration",
            value: duration
        )
        
        StructuredLogger.shared.info(
            "Health sync completed",
            category: "metrics",
            context: ["duration": String(format: "%.3f", duration)]
        )
    }
    
    // MARK: - 搜索延迟
    
    func measureSearchLatency(query: String, resultCount: Int, operation: () async -> Void) async {
        let traceID = PerformanceMonitor.shared.startTrace(
            name: "dashboard_search",
            attributes: [
                "query_length": String(query.count),
                "result_count": String(resultCount)
            ]
        )
        
        let start = Date()
        
        await operation()
        
        let duration = Date().timeIntervalSince(start)
        
        PerformanceMonitor.shared.stopTrace(traceID, metrics: [
            "latency": duration,
            "results": Double(resultCount)
        ])
        
        PerformanceMonitor.shared.recordCustomMetric(
            name: "search_latency",
            value: duration
        )
        
        StructuredLogger.shared.info(
            "Search completed",
            category: "metrics",
            context: [
                "query": query,
                "results": String(resultCount),
                "latency": String(format: "%.3f", duration)
            ]
        )
    }
    
    // MARK: - 操作成功率
    
    func recordOperationSuccess(_ operation: String) {
        operationSuccessCount[operation, default: 0] += 1
        
        PerformanceMonitor.shared.incrementCounter(name: "operation_success_\(operation)")
        
        StructuredLogger.shared.debug(
            "Operation succeeded",
            category: "metrics",
            context: ["operation": operation]
        )
    }
    
    func recordOperationFailure(_ operation: String, error: Error) {
        operationFailureCount[operation, default: 0] += 1
        
        PerformanceMonitor.shared.incrementCounter(name: "operation_failure_\(operation)")
        
        StructuredLogger.shared.error(
            "Operation failed",
            category: "metrics",
            context: [
                "operation": operation,
                "error": error.localizedDescription
            ]
        )
    }
    
    func getOperationSuccessRate(for operation: String) -> Double {
        let success = operationSuccessCount[operation] ?? 0
        let failure = operationFailureCount[operation] ?? 0
        let total = success + failure
        
        guard total > 0 else { return 0 }
        
        return Double(success) / Double(total) * 100
    }
    
    // MARK: - 错误率分类
    
    func getErrorRateByCategory() -> [String: Double] {
        var errorRates: [String: Double] = [:]
        
        for (operation, failures) in operationFailureCount {
            let success = operationSuccessCount[operation] ?? 0
            let total = success + failures
            
            guard total > 0 else { continue }
            
            let errorRate = Double(failures) / Double(total) * 100
            errorRates[operation] = errorRate
        }
        
        return errorRates
    }
    
    // MARK: - 统计报告
    
    func generateMetricsReport() -> String {
        var report = "=== Dashboard Metrics Report ===\n\n"
        
        // 操作成功率
        report += "Operation Success Rates:\n"
        for operation in Set(operationSuccessCount.keys).union(operationFailureCount.keys) {
            let rate = getOperationSuccessRate(for: operation)
            report += "  \(operation): \(String(format: "%.2f", rate))%\n"
        }
        
        // 错误率
        report += "\nError Rates by Category:\n"
        for (category, rate) in getErrorRateByCategory() {
            report += "  \(category): \(String(format: "%.2f", rate))%\n"
        }
        
        // 性能指标
        if let searchLatency = PerformanceMonitor.shared.getCustomMetricStats(for: "search_latency") {
            report += "\nSearch Performance:\n"
            report += "  Average: \(String(format: "%.3f", searchLatency.average))s\n"
            report += "  Min: \(String(format: "%.3f", searchLatency.min))s\n"
            report += "  Max: \(String(format: "%.3f", searchLatency.max))s\n"
        }
        
        if let healthSync = PerformanceMonitor.shared.getCustomMetricStats(for: "health_sync_duration") {
            report += "\nHealth Sync Performance:\n"
            report += "  Average: \(String(format: "%.3f", healthSync.average))s\n"
            report += "  Min: \(String(format: "%.3f", healthSync.min))s\n"
            report += "  Max: \(String(format: "%.3f", healthSync.max))s\n"
        }
        
        return report
    }
    
    func logMetricsReport() {
        let report = generateMetricsReport()
        StructuredLogger.shared.info(report, category: "metrics")
    }
}
