import Foundation
import OSLog

enum Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.personalos"
    
    static let network = OSLog(subsystem: subsystem, category: "Network")
    static let health = OSLog(subsystem: subsystem, category: "Health")
    static let trading = OSLog(subsystem: subsystem, category: "Trading")
    static let general = OSLog(subsystem: subsystem, category: "General")
    
    static func log(_ message: String, category: OSLog = Logger.general, type: OSLogType = .default) {
        os_log("%{public}@", log: category, type: type, message)
    }
    
    static func error(_ message: String, category: OSLog = Logger.general) {
        os_log("%{public}@", log: category, type: .error, message)
    }
    
    static func debug(_ message: String, category: OSLog = Logger.general) {
        #if DEBUG
        os_log("%{public}@", log: category, type: .debug, message)
        #endif
    }
}
