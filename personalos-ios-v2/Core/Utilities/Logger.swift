import Foundation
import OSLog

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.personalos"
    
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let health = OSLog(subsystem: subsystem, category: "Health")
    static let trading = OSLog(subsystem: subsystem, category: "Trading")
    static let general = OSLog(subsystem: subsystem, category: "General")
    static let performance = OSLog(subsystem: subsystem, category: "Performance")
    static let sync = OSLog(subsystem: subsystem, category: "Sync")
    static let analytics = OSLog(subsystem: subsystem, category: "Analytics")
    
    static func log(_ message: String, category: OSLog = Logger.general, type: OSLogType = .default) {
        os_log("%{public}@", log: category, type: type, message)
        
        // 同时记录到分析系统
        if type == .error || type == .fault {
            AnalyticsLogger.shared.log(.error(
                domain: categoryName(category),
                code: 0,
                description: message
            ))
        }
    }
    
    static func error(_ message: String, category: OSLog = Logger.general) {
        os_log("%{public}@", log: category, type: .error, message)
        
        AnalyticsLogger.shared.log(.error(
            domain: categoryName(category),
            code: 0,
            description: message
        ))
    }
    
    static func warning(_ message: String, category: OSLog = Logger.general) {
        os_log("%{public}@", log: category, type: .default, message)
    }
    
    static func debug(_ message: String, category: OSLog = Logger.general) {
        #if DEBUG
        os_log("%{public}@", log: category, type: .debug, message)
        #endif
    }
    
    private static func categoryName(_ category: OSLog) -> String {
        switch category {
        case network: return "Network"
        case health: return "Health"
        case trading: return "Trading"
        case performance: return "Performance"
        case sync: return "Sync"
        case analytics: return "Analytics"
        default: return "General"
        }
    }
}
