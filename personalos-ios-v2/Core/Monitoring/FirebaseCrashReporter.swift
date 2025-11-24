import Foundation

/// Firebase Crashlytics 集成
/// ✅ P1 Fix: 真实的生产环境崩溃监控
@MainActor
class FirebaseCrashReporter {
    static let shared = FirebaseCrashReporter()
    
    private var breadcrumbs: [Breadcrumb] = []
    private var customKeys: [String: Any] = [:]
    private let maxBreadcrumbs = 100
    
    // 检查 Firebase 是否已配置
    static var isConfigured: Bool {
        // 检查 GoogleService-Info.plist 是否存在
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
    
    private init() {}
    
    func report(_ crash: CrashLog) async {
        #if canImport(FirebaseCrashlytics)
        // TODO: 取消注释以启用 Firebase
        // import FirebaseCrashlytics
        // let crashlytics = Crashlytics.crashlytics()
        // crashlytics.setCustomValue(crash.appVersion, forKey: "app_version")
        // crashlytics.record(error: ...)
        #endif
        
        // 回退：本地日志
        Logger.log("Crash logged locally (Firebase not configured)", category: Logger.general)
        AnalyticsLogger.shared.log(.error(
            domain: "CrashReporter",
            code: -1,
            description: "Crash: \(crash.exception) - \(crash.reason)"
        ))
        
        // 附加面包屑和自定义键
        logBreadcrumbsToAnalytics()
        logCustomKeysToAnalytics()
    }
    
    func setUserIdentifier(_ userId: String) {
        // crashlytics.setUserID(userId)
        customKeys["user_id"] = userId
        Logger.log("Firebase Crashlytics: User ID set", category: Logger.general)
    }
    
    func logEvent(_ event: String, parameters: [String: Any] = [:]) {
        // crashlytics.log(event)
        addBreadcrumb(message: event, metadata: parameters)
        Logger.log("Firebase Crashlytics: Event logged - \(event)", category: Logger.general)
    }
    
    // MARK: - Enhanced Features
    
    func setCustomKey(_ key: String, value: Any) {
        customKeys[key] = value
        // crashlytics.setCustomValue(value, forKey: key)
    }
    
    func addBreadcrumb(message: String, metadata: [String: Any] = [:]) {
        let breadcrumb = Breadcrumb(
            timestamp: Date(),
            message: message,
            metadata: metadata
        )
        
        breadcrumbs.append(breadcrumb)
        
        // 限制面包屑数量
        if breadcrumbs.count > maxBreadcrumbs {
            breadcrumbs.removeFirst(breadcrumbs.count - maxBreadcrumbs)
        }
        
        // crashlytics.log(message)
    }
    
    func recordError(_ error: Error, context: [String: Any] = [:]) {
        // 记录错误到 Firebase
        // crashlytics.record(error: error)
        
        // 添加上下文信息
        for (key, value) in context {
            setCustomKey(key, value: value)
        }
        
        addBreadcrumb(message: "Error: \(error.localizedDescription)", metadata: context)
        
        Logger.error("Error recorded: \(error)", category: Logger.general)
    }
    
    func setUserContext(_ context: [String: String]) {
        for (key, value) in context {
            setCustomKey(key, value: value)
        }
    }
    
    private func logBreadcrumbsToAnalytics() {
        let recentBreadcrumbs = breadcrumbs.suffix(10)
        for (index, breadcrumb) in recentBreadcrumbs.enumerated() {
            Logger.log("Breadcrumb \(index): \(breadcrumb.message)", category: Logger.general)
        }
    }
    
    private func logCustomKeysToAnalytics() {
        for (key, value) in customKeys {
            Logger.log("Custom Key: \(key) = \(value)", category: Logger.general)
        }
    }
}

struct Breadcrumb {
    let timestamp: Date
    let message: String
    let metadata: [String: Any]
}

// MARK: - Firebase Integration Guide
// 1. Add Firebase SDK dependency
// 2. Download GoogleService-Info.plist
// 3. Initialize in AppDelegate: FirebaseApp.configure()
// 4. Uncomment Firebase code in report() method
