import Foundation
import UIKit

/// Security validation service
final class SecurityValidator {
    static let shared = SecurityValidator()
    
    private init() {}
    
    // MARK: - Jailbreak Detection
    
    /// Check if device is jailbroken
    func isJailbroken() -> Bool {
        #if targetEnvironment(simulator)
        return false
        #else
        return checkJailbreakFiles() || checkJailbreakPaths() || checkSuspiciousApps()
        #endif
    }
    
    private func checkJailbreakFiles() -> Bool {
        let jailbreakFiles = [
            "/Applications/Cydia.app",
            "/Library/MobileSubstrate/MobileSubstrate.dylib",
            "/bin/bash",
            "/usr/sbin/sshd",
            "/etc/apt",
            "/private/var/lib/apt/",
            "/private/var/lib/cydia",
            "/private/var/mobile/Library/SBSettings/Themes",
            "/private/var/tmp/cydia.log",
            "/private/var/stash",
            "/usr/libexec/sftp-server",
            "/usr/bin/ssh"
        ]
        
        for path in jailbreakFiles {
            if FileManager.default.fileExists(atPath: path) {
                Logger.warning("Jailbreak file detected: \(path)", category: Logger.general)
                return true
            }
        }
        
        return false
    }
    
    private func checkJailbreakPaths() -> Bool {
        // Try to write to a restricted path
        let testPath = "/private/jailbreak_test.txt"
        do {
            try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
            try FileManager.default.removeItem(atPath: testPath)
            Logger.warning("Able to write to restricted path - jailbreak detected", category: Logger.general)
            return true
        } catch {
            // Unable to write - good, device is not jailbroken
            return false
        }
    }
    
    private func checkSuspiciousApps() -> Bool {
        let suspiciousApps = [
            "cydia://",
            "sileo://",
            "zbra://",
            "filza://"
        ]
        
        for urlScheme in suspiciousApps {
            if let url = URL(string: urlScheme),
               UIApplication.shared.canOpenURL(url) {
                Logger.warning("Suspicious app detected: \(urlScheme)", category: Logger.general)
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Debugger Detection
    
    /// Check if debugger is attached
    func isDebuggerAttached() -> Bool {
        var info = kinfo_proc()
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, getpid()]
        var size = MemoryLayout<kinfo_proc>.stride
        
        let result = sysctl(&mib, UInt32(mib.count), &info, &size, nil, 0)
        
        guard result == 0 else {
            return false
        }
        
        return (info.kp_proc.p_flag & P_TRACED) != 0
    }
    
    // MARK: - Certificate Validation
    
    /// Validate SSL certificate
    func validateCertificate(_ trust: SecTrust, for host: String) -> Bool {
        // Get the certificate chain
        guard let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            Logger.error("Failed to get server certificate", category: Logger.general)
            return false
        }
        
        // In production, you would compare against pinned certificates
        // For now, we'll use the system's default validation
        
        var error: CFError?
        let isValid = SecTrustEvaluateWithError(trust, &error)
        
        if let error = error {
            Logger.error("Certificate validation failed: \(error)", category: Logger.general)
            return false
        }
        
        return isValid
    }
    
    /// Validate certificate against pinned certificates
    func validateCertificatePinning(_ trust: SecTrust, for host: String, pinnedCertificates: [Data]) -> Bool {
        guard let serverCertificate = SecTrustGetCertificateAtIndex(trust, 0) else {
            return false
        }
        
        let serverCertificateData = SecCertificateCopyData(serverCertificate) as Data
        
        // Check if server certificate matches any pinned certificate
        for pinnedCert in pinnedCertificates {
            if serverCertificateData == pinnedCert {
                Logger.log("Certificate pinning validation passed for \(host)", category: Logger.general)
                return true
            }
        }
        
        Logger.warning("Certificate pinning validation failed for \(host)", category: Logger.general)
        return false
    }
    
    // MARK: - Security Checks
    
    /// Perform comprehensive security check
    func performSecurityCheck() -> SecurityCheckResult {
        var issues: [SecurityIssue] = []
        
        if isJailbroken() {
            issues.append(.jailbroken)
        }
        
        if isDebuggerAttached() {
            issues.append(.debuggerAttached)
        }
        
        let environment = EnvironmentManager.shared.environment
        if environment == .production && EnvironmentManager.shared.isDebugMode() {
            issues.append(.debugModeInProduction)
        }
        
        return SecurityCheckResult(issues: issues)
    }
}

/// Security check result
struct SecurityCheckResult {
    let issues: [SecurityIssue]
    
    var isSecure: Bool {
        return issues.isEmpty
    }
    
    var hasJailbreakIssue: Bool {
        return issues.contains(.jailbroken)
    }
    
    var hasDebuggerIssue: Bool {
        return issues.contains(.debuggerAttached)
    }
}

/// Security issues
enum SecurityIssue: String, CaseIterable {
    case jailbroken = "Device is jailbroken"
    case debuggerAttached = "Debugger is attached"
    case debugModeInProduction = "Debug mode enabled in production"
    case certificateValidationFailed = "Certificate validation failed"
    
    var severity: SecuritySeverity {
        switch self {
        case .jailbroken, .certificateValidationFailed:
            return .critical
        case .debuggerAttached:
            return .high
        case .debugModeInProduction:
            return .medium
        }
    }
}

/// Security severity levels
enum SecuritySeverity {
    case low
    case medium
    case high
    case critical
}
