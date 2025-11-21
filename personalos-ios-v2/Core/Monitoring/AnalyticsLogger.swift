import Foundation
import OSLog

enum AnalyticsEvent {
    case appLaunched
    case userAction(name: String, properties: [String: Any]?)
    case screenView(name: String)
    case error(domain: String, code: Int, description: String)
    case performance(metric: String, duration: TimeInterval)
    
    var name: String {
        switch self {
        case .appLaunched: return "app_launched"
        case .userAction(let name, _): return "user_\(name)"
        case .screenView(let name): return "screen_\(name)"
        case .error: return "error"
        case .performance(let metric, _): return "perf_\(metric)"
        }
    }
}

@MainActor
class AnalyticsLogger {
    static let shared = AnalyticsLogger()
    
    private let logger = OSLog(subsystem: "com.personalos.v2", category: "analytics")
    private var events: [AnalyticsEventLog] = []
    
    private init() {}
    
    func log(_ event: AnalyticsEvent) {
        let eventLog = AnalyticsEventLog(
            timestamp: Date(),
            event: event.name,
            properties: extractProperties(from: event)
        )
        
        events.append(eventLog)
        
        os_log(.info, log: logger, "📊 Analytics: %{public}@", event.name)
        
        // 上报到分析服务
        Task {
            await uploadEvent(eventLog)
        }
    }
    
    private func extractProperties(from event: AnalyticsEvent) -> [String: String] {
        switch event {
        case .appLaunched:
            return [
                "version": AppConfig.version,
                "build": AppConfig.buildNumber
            ]
        case .userAction(_, let properties):
            return properties?.compactMapValues { "\($0)" } ?? [:]
        case .screenView(let name):
            return ["screen": name]
        case .error(let domain, let code, let description):
            return [
                "domain": domain,
                "code": "\(code)",
                "description": description
            ]
        case .performance(let metric, let duration):
            return [
                "metric": metric,
                "duration": String(format: "%.3f", duration)
            ]
        }
    }
    
    private func uploadEvent(_ event: AnalyticsEventLog) async {
        // TODO: 集成分析服务（Firebase Analytics, Mixpanel 等）
        #if DEBUG
        print("📤 Would upload analytics event in production: \(event.event)")
        #endif
    }
    
    func getRecentEvents(limit: Int = 100) -> [AnalyticsEventLog] {
        Array(events.suffix(limit))
    }
}

struct AnalyticsEventLog: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let event: String
    let properties: [String: String]
    
    enum CodingKeys: String, CodingKey {
        case timestamp, event, properties
    }
}
