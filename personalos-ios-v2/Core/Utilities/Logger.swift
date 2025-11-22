import Foundation
import OSLog

struct Logger {
    static let general = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "general")
    static let network = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "network")
    static let data = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "data")
    static let ui = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "ui")
    static let analytics = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "analytics")
    static let health = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "health")
    static let performance = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "performance")
    static let sync = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "sync")
    static let trading = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.personalos", category: "trading")
    
    static func log(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .info, message)
    }
    
    static func error(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .error, message)
    }
    
    static func warning(_ message: String, category: OSLog = general) {
        os_log("%{public}@", log: category, type: .default, message)
    }
    
    static func debug(_ message: String, category: OSLog = general) {
        #if DEBUG
        os_log("%{public}@", log: category, type: .debug, message)
        #endif
    }
}
