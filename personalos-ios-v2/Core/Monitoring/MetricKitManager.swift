import Foundation
import MetricKit
import OSLog

@MainActor
final class MetricKitManager: NSObject, MXMetricManagerSubscriber {
    static let shared = MetricKitManager()
    
    private let logger = OSLog(subsystem: "com.personalos.v2", category: "metrickit")
    private var diagnosticPayloads: [MXDiagnosticPayload] = []
    private var metricPayloads: [MXMetricPayload] = []
    
    private override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }
    
    deinit {
        MXMetricManager.shared.remove(self)
    }
    
    // MARK: - MXMetricManagerSubscriber
    
    nonisolated func didReceive(_ payloads: [MXMetricPayload]) {
        Task { @MainActor in
            handleMetricPayloads(payloads)
        }
    }
    
    nonisolated func didReceive(_ payloads: [MXDiagnosticPayload]) {
        Task { @MainActor in
            handleDiagnosticPayloads(payloads)
        }
    }
    
    // MARK: - Metric Handling
    
    private func handleMetricPayloads(_ payloads: [MXMetricPayload]) {
        metricPayloads.append(contentsOf: payloads)
        
        for payload in payloads {
            os_log(.info, log: logger, "📊 Received metric payload: %{public}@", payload.timeStampBegin.description)
            
            // CPU Metrics
            if let cpuMetrics = payload.cpuMetrics {
                logCPUMetrics(cpuMetrics)
            }
            
            // Memory Metrics
            if let memoryMetrics = payload.memoryMetrics {
                logMemoryMetrics(memoryMetrics)
            }
            
            // Display Metrics
            if let displayMetrics = payload.displayMetrics {
                logDisplayMetrics(displayMetrics)
            }
            
            // Network Metrics
            if let networkMetrics = payload.networkTransferMetrics {
                logNetworkMetrics(networkMetrics)
            }
            
            // App Launch Metrics
            if let launchMetrics = payload.applicationLaunchMetrics {
                logLaunchMetrics(launchMetrics)
            }
            
            // Persist payload
            saveMetricPayload(payload)
        }
    }
    
    private func handleDiagnosticPayloads(_ payloads: [MXDiagnosticPayload]) {
        diagnosticPayloads.append(contentsOf: payloads)
        
        for payload in payloads {
            os_log(.error, log: logger, "🔥 Received diagnostic payload: %{public}@", payload.timeStampBegin.description)
            
            // Crash Diagnostics
            if let crashDiagnostics = payload.crashDiagnostics {
                for crash in crashDiagnostics {
                    logCrashDiagnostic(crash)
                }
            }
            
            // Hang Diagnostics
            if let hangDiagnostics = payload.hangDiagnostics {
                for hang in hangDiagnostics {
                    logHangDiagnostic(hang)
                }
            }
            
            // CPU Exception Diagnostics
            if let cpuExceptions = payload.cpuExceptionDiagnostics {
                for exception in cpuExceptions {
                    logCPUException(exception)
                }
            }
            
            // Disk Write Exception Diagnostics
            if let diskExceptions = payload.diskWriteExceptionDiagnostics {
                for exception in diskExceptions {
                    logDiskException(exception)
                }
            }
            
            saveDiagnosticPayload(payload)
        }
    }
    
    // MARK: - Logging
    
    private func logCPUMetrics(_ metrics: MXCPUMetrics) {
        let cumulativeTime = metrics.cumulativeCPUTime.converted(to: .seconds).value
        os_log(.info, log: logger, "⚡️ CPU Time: %.2f seconds", cumulativeTime)
        
        AnalyticsLogger.shared.log(.performance(metric: "cpu_time", duration: cumulativeTime))
    }
    
    private func logMemoryMetrics(_ metrics: MXMemoryMetrics) {
        let peakMemory = metrics.peakMemoryUsage.converted(to: .megabytes).value
        let avgMemory = metrics.averageSuspendedMemory?.averageMemory.converted(to: .megabytes).value ?? 0
        
        os_log(.info, log: logger, "💾 Memory - Peak: %.2f MB, Avg Suspended: %.2f MB", peakMemory, avgMemory)
        
        AnalyticsLogger.shared.log(.custom(name: "memory_usage", properties: [
            "peak_mb": peakMemory,
            "avg_suspended_mb": avgMemory
        ]))
    }
    
    private func logDisplayMetrics(_ metrics: MXDisplayMetrics) {
        let avgPixelLuminance = metrics.averagePixelLuminance.averageMeasurement.value
        
        os_log(.info, log: logger, "🖥️ Display - Avg Luminance: %.2f", avgPixelLuminance)
    }
    
    private func logNetworkMetrics(_ metrics: MXNetworkTransferMetrics) {
        let wifiUp = metrics.wifiUpload.converted(to: .megabytes).value
        let wifiDown = metrics.wifiDownload.converted(to: .megabytes).value
        let cellUp = metrics.cellularUpload.converted(to: .megabytes).value
        let cellDown = metrics.cellularDownload.converted(to: .megabytes).value
        
        os_log(.info, log: logger, "📡 Network - WiFi: ↑%.2f MB ↓%.2f MB, Cellular: ↑%.2f MB ↓%.2f MB",
               wifiUp, wifiDown, cellUp, cellDown)
        
        AnalyticsLogger.shared.log(.custom(name: "network_usage", properties: [
            "wifi_upload_mb": wifiUp,
            "wifi_download_mb": wifiDown,
            "cellular_upload_mb": cellUp,
            "cellular_download_mb": cellDown
        ]))
    }
    
    private func logLaunchMetrics(_ metrics: MXAppLaunchMetrics) {
        let launchTime = metrics.histogrammedTimeToFirstDraw.averageMeasurement.converted(to: .milliseconds).value
        
        os_log(.info, log: logger, "🚀 Launch Time: %.0f ms", launchTime)
        
        AnalyticsLogger.shared.log(.performance(metric: "app_launch", duration: launchTime / 1000))
        
        if launchTime > 2000 {
            Logger.warning("Slow app launch detected: \(launchTime)ms", category: Logger.performance)
        }
    }
    
    private func logCrashDiagnostic(_ diagnostic: MXCrashDiagnostic) {
        let signal = diagnostic.signal?.rawValue ?? "Unknown"
        let terminationReason = diagnostic.terminationReason ?? "Unknown"
        
        os_log(.fault, log: logger, "💥 Crash - Signal: %{public}@, Reason: %{public}@",
               signal, terminationReason)
        
        Logger.error("Crash detected: Signal=\(signal), Reason=\(terminationReason)", category: Logger.general)
        
        AnalyticsLogger.shared.log(.error(
            message: "App Crash",
            error: NSError(domain: "MetricKit", code: -1, userInfo: [
                "signal": signal,
                "reason": terminationReason
            ])
        ))
    }
    
    private func logHangDiagnostic(_ diagnostic: MXHangDiagnostic) {
        let duration = diagnostic.hangDuration.converted(to: .seconds).value
        
        os_log(.error, log: logger, "⏸️ Hang detected: %.2f seconds", duration)
        
        Logger.warning("App hang detected: \(duration)s", category: Logger.performance)
        
        AnalyticsLogger.shared.log(.custom(name: "app_hang", properties: [
            "duration_seconds": duration
        ]))
    }
    
    private func logCPUException(_ diagnostic: MXCPUExceptionDiagnostic) {
        let totalTime = diagnostic.totalCPUTime.converted(to: .seconds).value
        
        os_log(.error, log: logger, "⚠️ CPU Exception: %.2f seconds", totalTime)
        
        Logger.warning("CPU exception: \(totalTime)s", category: Logger.performance)
    }
    
    private func logDiskException(_ diagnostic: MXDiskWriteExceptionDiagnostic) {
        let totalWrites = diagnostic.totalWritesCaused.converted(to: .megabytes).value
        
        os_log(.error, log: logger, "💿 Disk Write Exception: %.2f MB", totalWrites)
        
        Logger.warning("Disk write exception: \(totalWrites)MB", category: Logger.performance)
    }
    
    // MARK: - Persistence
    
    private func saveMetricPayload(_ payload: MXMetricPayload) {
        guard let jsonData = payload.jsonRepresentation() else { return }
        
        let filename = "metrics_\(payload.timeStampBegin.timeIntervalSince1970).json"
        let url = getMetricsDirectory().appendingPathComponent(filename)
        
        try? jsonData.write(to: url)
    }
    
    private func saveDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        guard let jsonData = payload.jsonRepresentation() else { return }
        
        let filename = "diagnostics_\(payload.timeStampBegin.timeIntervalSince1970).json"
        let url = getDiagnosticsDirectory().appendingPathComponent(filename)
        
        try? jsonData.write(to: url)
    }
    
    private func getMetricsDirectory() -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("metrickit/metrics")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    private func getDiagnosticsDirectory() -> URL {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("metrickit/diagnostics")
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        return url
    }
    
    // MARK: - Public API
    
    func getRecentMetrics(limit: Int = 10) -> [MXMetricPayload] {
        Array(metricPayloads.suffix(limit))
    }
    
    func getRecentDiagnostics(limit: Int = 10) -> [MXDiagnosticPayload] {
        Array(diagnosticPayloads.suffix(limit))
    }
}
