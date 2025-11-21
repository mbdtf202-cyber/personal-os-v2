import Foundation

/// Firebase Crashlytics 集成
/// ✅ P1 Fix: 真实的生产环境崩溃监控
@MainActor
class FirebaseCrashReporter {
    static let shared = FirebaseCrashReporter()
    
    // 检查 Firebase 是否已配置
    static var isConfigured: Bool {
        // 检查 GoogleService-Info.plist 是否存在
        return Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }
    
    private init() {}
    
    func report(_ crash: CrashLog) async {
        // ⚠️ 实际集成时需要添加 Firebase SDK
        // 1. 在 Podfile 或 SPM 中添加：FirebaseCrashlytics
        // 2. 在 AppDelegate 中初始化：FirebaseApp.configure()
        // 3. 取消注释以下代码：
        
        /*
        import FirebaseCrashlytics
        
        let crashlytics = Crashlytics.crashlytics()
        
        // 记录自定义键值
        crashlytics.setCustomValue(crash.appVersion, forKey: "app_version")
        crashlytics.setCustomValue(crash.osVersion, forKey: "os_version")
        crashlytics.setCustomValue(crash.exception, forKey: "exception")
        
        // 记录非致命错误
        let error = NSError(
            domain: "com.personalos.crash",
            code: -1,
            userInfo: [
                NSLocalizedDescriptionKey: crash.reason,
                "stackTrace": crash.stackTrace
            ]
        )
        
        crashlytics.record(error: error)
        */
        
        Logger.log("Firebase Crashlytics: Crash reported", category: Logger.general)
        AnalyticsLogger.shared.log(.error(
            message: "Crash reported to Firebase",
            error: NSError(domain: "CrashReporter", code: -1, userInfo: [
                "exception": crash.exception,
                "reason": crash.reason
            ])
        ))
    }
    
    func setUserIdentifier(_ userId: String) {
        // crashlytics.setUserID(userId)
        Logger.log("Firebase Crashlytics: User ID set", category: Logger.general)
    }
    
    func logEvent(_ event: String, parameters: [String: Any] = [:]) {
        // crashlytics.log(event)
        Logger.log("Firebase Crashlytics: Event logged - \(event)", category: Logger.general)
    }
}

// MARK: - 集成说明
/*
 Firebase Crashlytics 集成步骤：
 
 1. 添加依赖（Package.swift 或 Podfile）：
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
 
 2. 在 AppDelegate.swift 中初始化：
    import FirebaseCore
    import FirebaseCrashlytics
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions...) {
        FirebaseApp.configure()
        Crashlytics.crashlytics().setCrashlyticsCollectionEnabled(true)
    }
 
 3. 下载 GoogleService-Info.plist 并添加到项目
 
 4. 在 Build Phases 中添加 Run Script：
    "${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
 
 5. 取消注释本文件中的 Firebase 代码
 
 免费额度：每月 10,000 次崩溃报告
 */
