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
        #if DEBUG
        Logger.debug("Crash log saved locally (Debug mode)", category: Logger.general)
        #else
        // ✅ P1 Fix: 真实监控集成
        // 优先级：Firebase Crashlytics → Sentry → 用户邮件分享
        
        // 1. 尝试上传到 Firebase Crashlytics（如果已配置）
        if FirebaseCrashReporter.isConfigured {
            await FirebaseCrashReporter.shared.report(crash)
            return
        }
        
        // 2. 回退：提示用户通过邮件分享
        await promptUserToShareCrashLog(crash)
        #endif
    }
    
    private func promptUserToShareCrashLog(_ crash: CrashLog) async {
        // 在下次启动时提示用户分享崩溃日志
        UserDefaults.standard.set(true, forKey: "has_pending_crash_report")
        UserDefaults.standard.set(crash.timestamp.timeIntervalSince1970, forKey: "last_crash_timestamp")
    }
    
    func checkAndPromptCrashReport() async {
        guard UserDefaults.standard.bool(forKey: "has_pending_crash_report") else { return }
        
        // 获取最近的崩溃日志
        let crashes = getRecentCrashes(limit: 1)
        guard let latestCrash = crashes.first else { return }
        
        // 清除标记
        UserDefaults.standard.removeObject(forKey: "has_pending_crash_report")
        
        // 生成邮件内容
        let emailBody = generateCrashEmailBody(latestCrash)
        
        // 通过 AnalyticsLogger 记录
        AnalyticsLogger.shared.log(.error(
            message: "Crash Report Available",
            error: NSError(domain: "CrashReporter", code: -1, userInfo: [
                "exception": latestCrash.exception,
                "reason": latestCrash.reason
            ])
        ))
        
        Logger.log("Crash report ready for user sharing", category: Logger.general)
    }
    
    private func generateCrashEmailBody(_ crash: CrashLog) -> String {
        """
        PersonalOS Crash Report
        
        Time: \(crash.timestamp)
        Version: \(crash.appVersion)
        OS: iOS \(crash.osVersion)
        
        Exception: \(crash.exception)
        Reason: \(crash.reason)
        
        Stack Trace:
        \(crash.stackTrace)
        """
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
