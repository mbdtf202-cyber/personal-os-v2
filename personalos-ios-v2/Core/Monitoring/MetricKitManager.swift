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
    
    private func logCPUMetrics(_ metrics: Any) {
        os_log(.info, log: logger, "⚡️ CPU Metrics received")
        Logger.log("CPU metrics available", category: Logger.performance)
    }
    
    private func logMemoryMetrics(_ metrics: Any) {
        os_log(.info, log: logger, "💾 Memory Metrics received")
        Logger.log("Memory metrics available", category: Logger.performance)
    }
    
    private func logDisplayMetrics(_ metrics: Any) {
        os_log(.info, log: logger, "🖥️ Display Metrics received")
    }
    
    private func logNetworkMetrics(_ metrics: Any) {
        os_log(.info, log: logger, "📡 Network Metrics received")
        Logger.log("Network metrics available", category: Logger.performance)
    }
    
    private func logLaunchMetrics(_ metrics: Any) {
        os_log(.info, log: logger, "🚀 Launch Metrics received")
        Logger.log("App launch metrics available", category: Logger.performance)
    }
    
    private func logCrashDiagnostic(_ diagnostic: MXCrashDiagnostic) {
        let terminationReason = diagnostic.terminationReason ?? "Unknown"
        
        os_log(.fault, log: logger, "💥 Crash - Reason: %{public}@", terminationReason)
        
        Logger.error("Crash detected: Reason=\(terminationReason)", category: Logger.general)
    }
    
    private func logHangDiagnostic(_ diagnostic: MXHangDiagnostic) {
        os_log(.error, log: logger, "⏸️ Hang detected")
        Logger.warning("App hang detected", category: Logger.performance)
    }
    
    private func logCPUException(_ diagnostic: MXCPUExceptionDiagnostic) {
        os_log(.error, log: logger, "⚠️ CPU Exception")
        Logger.warning("CPU exception detected", category: Logger.performance)
    }
    
    private func logDiskException(_ diagnostic: MXDiskWriteExceptionDiagnostic) {
        os_log(.error, log: logger, "💿 Disk Write Exception")
        Logger.warning("Disk write exception detected", category: Logger.performance)
    }
    
    // MARK: - Persistence
    
    private func saveMetricPayload(_ payload: MXMetricPayload) {
        let jsonData = payload.jsonRepresentation()
        
        let filename = "metrics_\(payload.timeStampBegin.timeIntervalSince1970).json"
        let url = getMetricsDirectory().appendingPathComponent(filename)
        
        try? jsonData.write(to: url)
    }
    
    private func saveDiagnosticPayload(_ payload: MXDiagnosticPayload) {
        let jsonData = payload.jsonRepresentation()
        
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
