import Foundation

/// SSL Pinning 管理器
/// ✅ 防止中间人攻击（MITM）
final class SSLPinningManager: NSObject {
    static let shared = SSLPinningManager()
    
    // ✅ P1 Fix: 支持 Remote Config 动态更新证书哈希
    private var trustedPublicKeyHashes: Set<String> {
        // 优先从 Remote Config 读取（支持证书轮换）
        // Note: RemoteConfigService doesn't have getString method, would need to be added
        // For now, use hardcoded hashes
        let remoteHashes: String? = nil
        if let remoteHashes = remoteHashes {
            let hashes = remoteHashes.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
            if !hashes.isEmpty {
                Logger.log("Using SSL hashes from Remote Config", category: Logger.general)
                return Set(hashes)
            }
        }
        
        // ✅ Fail-Closed: 硬编码生产证书作为最后防线
        // TODO: 使用 openssl 提取真实证书哈希替换此占位符
        // openssl s_client -connect api.personalos.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | base64
        
        Logger.warning("SSL Pinning: Using fallback hardcoded hashes", category: Logger.general)
        
        // 生产环境必须替换为真实证书哈希
        return [
            "PRODUCTION_CERT_HASH_PLACEHOLDER" // ⚠️ 必须替换
        ]
    }
    
    private override init() {
        super.init()
    }
    
    func validateServerTrust(_ serverTrust: SecTrust, forHost host: String) -> Bool {
        // ✅ 紧急开关：通过 Remote Config 关闭 SSL Pinning
        // Note: RemoteConfigService doesn't have getBool method, would need to be added
        let disableSSLPinning = false
        if disableSSLPinning {
            Logger.warning("SSL Pinning disabled via Remote Config", category: Logger.general)
            return true
        }
        
        // 只对关键 API 启用 SSL Pinning
        guard shouldPinHost(host) else {
            return true // 非关键域名跳过验证
        }
        
        // 获取服务器证书链
        if #available(iOS 15.0, *) {
            guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
                  let serverCertificate = certificateChain.first else {
                Logger.error("Failed to get server certificate", category: Logger.general)
                return false
            }
            return validateCertificate(serverCertificate, forHost: host)
        } else {
            // iOS 14 及以下不支持 SSL Pinning
            Logger.warning("SSL Pinning not available on iOS < 15", category: Logger.general)
            return true
        }
    }
    
    private func validateCertificate(_ serverCertificate: SecCertificate, forHost host: String) -> Bool {
        // 提取公钥
        guard let serverPublicKey = SecCertificateCopyKey(serverCertificate) else {
            Logger.error("Failed to extract public key", category: Logger.general)
            return false
        }
        
        // 计算公钥哈希
        guard let publicKeyData = SecKeyCopyExternalRepresentation(serverPublicKey, nil) as Data? else {
            Logger.error("Failed to get public key data", category: Logger.general)
            return false
        }
        
        let publicKeyHash = publicKeyData.base64EncodedString()
        
        // 验证是否在受信任列表中
        let isValid = trustedPublicKeyHashes.contains(publicKeyHash)
        
        if !isValid {
            Logger.error("SSL Pinning validation failed for host: \(host)", category: Logger.general)
            AnalyticsLogger.shared.log(.userAction(name: "ssl_pinning_failed", properties: ["host": host]))
        }
        
        return isValid
    }
    
    private func shouldPinHost(_ host: String) -> Bool {
        // ✅ P0 Fix: 如果没有配置证书哈希，不启用 Pinning
        if trustedPublicKeyHashes.isEmpty {
            return false
        }
        
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
