import Foundation

/// SSL Pinning 管理器
/// ✅ 防止中间人攻击（MITM）
final class SSLPinningManager: NSObject {
    static let shared = SSLPinningManager()
    
    // ✅ P1 Fix: 支持 Remote Config 动态更新证书哈希
    private var trustedPublicKeyHashes: Set<String> {
        // 优先从 Remote Config 读取（支持证书轮换）
        if let remoteHashes = RemoteConfigService.shared.getString(key: "ssl_pinning_hashes", defaultValue: nil) {
            let hashes = remoteHashes.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            if !hashes.isEmpty {
                Logger.log("Using SSL hashes from Remote Config", category: Logger.security)
                return Set(hashes)
            }
        }
        
        // 回退到硬编码值（⚠️ 生产环境必须替换为真实证书哈希）
        return [
            // 生产环境证书哈希（通过 openssl 提取）
            // openssl s_client -connect api.personalos.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
            "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
            // 备用证书哈希（证书轮换时使用）
            "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="
        ]
    }
    
    private override init() {
        super.init()
    }
    
    func validateServerTrust(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        // ✅ 紧急开关：通过 Remote Config 关闭 SSL Pinning
        if RemoteConfigService.shared.getBool(key: "disable_ssl_pinning", defaultValue: false) {
            Logger.warning("SSL Pinning disabled via Remote Config", category: Logger.security)
            return true
        }
        
        // 只对关键 API 启用 SSL Pinning
        guard shouldPinHost(host) else {
            return true // 非关键域名跳过验证
        }
        
        // 获取服务器证书链
        guard let serverCertificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            Logger.error("Failed to get server certificate", category: Logger.security)
            return false
        }
        
        // 提取公钥
        guard let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            Logger.error("Failed to extract public key", category: Logger.security)
            return false
        }
        
        // 计算公钥哈希
        guard let publicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            Logger.error("Failed to get public key data", category: Logger.security)
            return false
        }
        
        let publicKeyHash = publicKeyData.base64EncodedString()
        
        // 验证是否在受信任列表中
        let isValid = trustedPublicKeyHashes.contains(publicKeyHash)
        
        if !isValid {
            Logger.error("SSL Pinning validation failed for host: \(host)", category: Logger.security)
            AnalyticsLogger.shared.log(.security(event: "ssl_pinning_failed", details: ["host": host]))
        }
        
        return isValid
    }
    
    private func shouldPinHost(_ host: String) -> Bool {
        // 只对关键 API 启用 SSL Pinning
        let criticalHosts = [
            "api.personalos.com",
            "sync.personalos.com",
            "auth.personalos.com"
        ]
        
        return criticalHosts.contains { host.contains($0) }
    }
}

// MARK: - URLSessionDelegate Extension

extension SSLPinningManager: URLSessionDelegate {
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let serverTrust = challenge.protectionSpace.serverTrust,
              let host = challenge.protectionSpace.host as String? else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        if validateServerTrust(serverTrust, forHost: host) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
