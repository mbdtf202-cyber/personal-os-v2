import Foundation
import OSLog

@MainActor
class CrashReporter {
    static let shared = CrashReporter()
    
    private let logger = OSLog(subsystem: "com.personalos.v2", category: "crash")
    private var crashLogs: [CrashLog] = []
    
    private init() {
        setupCrashHandler()
    }
    
    private func setupCrashHandler() {
        NSSetUncaughtExceptionHandler { exception in
            Task { @MainActor in
                CrashReporter.shared.logCrash(
                    exception: exception.name.rawValue,
                    reason: exception.reason ?? "Unknown",
                    stackTrace: exception.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }
    
    func logCrash(exception: String, reason: String, stackTrace: String) {
        let crash = CrashLog(
            timestamp: Date(),
            exception: exception,
            reason: reason,
            stackTrace: stackTrace,
            appVersion: AppConfig.version,
            osVersion: UIDevice.current.systemVersion
        )
        
        crashLogs.append(crash)
        
        os_log(.fault, log: logger, """
        🔥 CRASH DETECTED
        Exception: %{public}@
        Reason: %{public}@
        Stack: %{public}@
        """, exception, reason, stackTrace)
        
        // 持久化崩溃日志
        saveCrashLog(crash)
        
        // 上报到远程服务（如果配置）
        Task {
            await uploadCrashLog(crash)
        }
    }
    
    private func saveCrashLog(_ crash: CrashLog) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        guard let data = try? encoder.encode(crash) else { return }
        
        let filename = "crash_\(crash.timestamp.timeIntervalSince1970).json"
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("crashes")
            .appendingPathComponent(filename)
        
        try? FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        
        try? data.write(to: url)
    }
    
    private func uploadCrashLog(_ crash: CrashLog) async {
        // 集成崩溃上报服务（Sentry, Firebase Crashlytics）
        #if DEBUG
        Logger.debug("Would upload crash log in production", category: Logger.general)
        #endif
    }
    
    func getRecentCrashes(limit: Int = 10) -> [CrashLog] {
        Array(crashLogs.suffix(limit))
    }
}

struct CrashLog: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let exception: String
    let reason: String
    let stackTrace: String
    let appVersion: String
    let osVersion: String
    
    enum CodingKeys: String, CodingKey {
        case timestamp, exception, reason, stackTrace, appVersion, osVersion
    }
}
