import Foundation
import AppTrackingTransparency
import AdSupport

/// Privacy and tracking management
@Observable
final class PrivacyManager {
    static let shared = PrivacyManager()
    
    private(set) var hasRequestedATT: Bool = false
    private(set) var trackingAuthorizationStatus: ATTrackingManager.AuthorizationStatus = .notDetermined
    
    private let attRequestedKey = "att_requested"
    
    private init() {
        loadATTStatus()
    }
    
    // MARK: - App Tracking Transparency
    
    /// Request tracking authorization
    @MainActor
    func requestTrackingAuthorization() async {
        guard !hasRequestedATT else {
            Logger.log("ATT already requested", category: Logger.general)
            return
        }
        
        Logger.log("Requesting App Tracking Transparency authorization", category: Logger.general)
        
        let status = await ATTrackingManager.requestTrackingAuthorization()
        
        trackingAuthorizationStatus = status
        hasRequestedATT = true
        
        UserDefaults.standard.set(true, forKey: attRequestedKey)
        
        logTrackingStatus(status)
    }
    
    /// Get current tracking authorization status
    func getCurrentTrackingStatus() -> ATTrackingManager.AuthorizationStatus {
        return ATTrackingManager.trackingAuthorizationStatus
    }
    
    /// Check if tracking is authorized
    func isTrackingAuthorized() -> Bool {
        return ATTrackingManager.trackingAuthorizationStatus == .authorized
    }
    
    private func loadATTStatus() {
        hasRequestedATT = UserDefaults.standard.bool(forKey: attRequestedKey)
        trackingAuthorizationStatus = ATTrackingManager.trackingAuthorizationStatus
    }
    
    private func logTrackingStatus(_ status: ATTrackingManager.AuthorizationStatus) {
        let statusString: String
        switch status {
        case .notDetermined:
            statusString = "Not Determined"
        case .restricted:
            statusString = "Restricted"
        case .denied:
            statusString = "Denied"
        case .authorized:
            statusString = "Authorized"
        @unknown default:
            statusString = "Unknown"
        }
        
        Logger.log("ATT Status: \(statusString)", category: Logger.general)
        
        AnalyticsLogger.shared.log(.userAction(
            name: "att_status_updated",
            properties: ["status": statusString]
        ))
    }
    
    // MARK: - Privacy Report
    
    /// Generate privacy report
    func generatePrivacyReport() -> PrivacyReport {
        let report = PrivacyReport(
            trackingStatus: trackingAuthorizationStatus,
            hasRequestedATT: hasRequestedATT,
            dataCollectionEnabled: isTrackingAuthorized(),
            thirdPartyServices: getThirdPartyServices(),
            dataRetentionPolicy: getDataRetentionPolicy()
        )
        
        return report
    }
    
    private func getThirdPartyServices() -> [ThirdPartyService] {
        var services: [ThirdPartyService] = []
        
        // Add third-party services used by the app
        if RemoteConfigService.shared.isFeatureEnabled("newsAggregator") {
            services.append(ThirdPartyService(
                name: "News API",
                purpose: "Fetch news articles",
                dataCollected: ["Search queries", "Reading preferences"]
            ))
        }
        
        if RemoteConfigService.shared.isFeatureEnabled("projectHub") {
            services.append(ThirdPartyService(
                name: "GitHub API",
                purpose: "Sync project repositories",
                dataCollected: ["Repository data", "Commit history"]
            ))
        }
        
        services.append(ThirdPartyService(
            name: "Firebase",
            purpose: "Analytics and crash reporting",
            dataCollected: ["App usage", "Crash logs", "Device info"]
        ))
        
        return services
    }
    
    private func getDataRetentionPolicy() -> DataRetentionPolicy {
        return DataRetentionPolicy(
            userDataRetention: "Indefinite (until user deletes)",
            analyticsRetention: "90 days",
            crashLogsRetention: "30 days",
            backupsRetention: "5 most recent backups"
        )
    }
    
    // MARK: - Data Access
    
    /// Request user data export
    func requestDataExport() async throws -> URL {
        Logger.log("User requested data export", category: Logger.general)
        
        // This would integrate with DataBackupService
        // For now, return a placeholder
        throw PrivacyError.notImplemented
    }
    
    /// Request data deletion (GDPR Right to be Forgotten)
    func requestDataDeletion() async throws {
        Logger.log("User requested data deletion (GDPR)", category: Logger.general)
        
        // This would integrate with DataBackupService
        throw PrivacyError.notImplemented
    }
}

/// Privacy report
struct PrivacyReport {
    let trackingStatus: ATTrackingManager.AuthorizationStatus
    let hasRequestedATT: Bool
    let dataCollectionEnabled: Bool
    let thirdPartyServices: [ThirdPartyService]
    let dataRetentionPolicy: DataRetentionPolicy
    
    var summary: String {
        let trackingStatusString: String
        switch trackingStatus {
        case .notDetermined:
            trackingStatusString = "Not yet determined"
        case .restricted:
            trackingStatusString = "Restricted by system"
        case .denied:
            trackingStatusString = "Denied by user"
        case .authorized:
            trackingStatusString = "Authorized by user"
        @unknown default:
            trackingStatusString = "Unknown"
        }
        
        return """
        Privacy Report
        ==============
        Tracking Status: \(trackingStatusString)
        Data Collection: \(dataCollectionEnabled ? "Enabled" : "Disabled")
        Third-Party Services: \(thirdPartyServices.count)
        """
    }
}

/// Third-party service information
struct ThirdPartyService {
    let name: String
    let purpose: String
    let dataCollected: [String]
}

/// Data retention policy
struct DataRetentionPolicy {
    let userDataRetention: String
    let analyticsRetention: String
    let crashLogsRetention: String
    let backupsRetention: String
}

/// Privacy errors
enum PrivacyError: Error, LocalizedError {
    case notImplemented
    case exportFailed
    case deletionFailed
    
    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Feature not yet implemented"
        case .exportFailed:
            return "Failed to export user data"
        case .deletionFailed:
            return "Failed to delete user data"
        }
    }
}
