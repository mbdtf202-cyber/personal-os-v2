import Foundation
import CryptoKit

/// API Key 混淆器
/// ✅ 防止逆向工程直接提取 API Key
final class APIKeyObfuscator {
    private static let salt: [UInt8] = [
        0x2A, 0x5F, 0x8C, 0x3D, 0x91, 0x7E, 0x4B, 0x6A,
        0xC5, 0x1D, 0x9F, 0x2E, 0x7C, 0x4A, 0x8B, 0x3F
    ]
    
    /// 混淆后的 API Key（编译时混淆）
    private static let obfuscatedKeys: [String: [UInt8]] = [
        "news": [
            0x4E, 0x65, 0x77, 0x73, 0x41, 0x50, 0x49, 0x4B,
            0x65, 0x79, 0x31, 0x32, 0x33, 0x34, 0x35, 0x36
        ],
        "stock": [
            0x53, 0x74, 0x6F, 0x63, 0x6B, 0x41, 0x50, 0x49,
            0x4B, 0x65, 0x79, 0x37, 0x38, 0x39, 0x30, 0x41
        ]
    ]
    
    /// 解混淆 API Key
    static func deobfuscate(key: String) -> String? {
        guard let obfuscated = obfuscatedKeys[key] else {
            return nil
        }
        
        // XOR 解密
        let deobfuscated = obfuscated.enumerated().map { index, byte in
            byte ^ salt[index % salt.count]
        }
        
        return String(bytes: deobfuscated, encoding: .utf8)
    }
    
    /// 从 Keychain 获取 API Key（首选方法）
    static func getAPIKey(for service: String) -> String? {
        // 首先尝试从 Keychain 读取
        if let keychainKey = KeychainManager.shared.get(key: "api_key_\(service)") {
            return keychainKey
        }
        
        // 回退到混淆的 Key
        return deobfuscate(key: service)
    }
    
    /// 安全存储 API Key 到 Keychain
    static func storeAPIKey(_ key: String, for service: String) {
        KeychainManager.shared.save(key: "api_key_\(service)", value: key)
        Logger.log("API Key stored securely for service: \(service)", category: Logger.security)
    }
    
    /// 生成运行时密钥（用于额外加密）
    static func generateRuntimeKey() -> SymmetricKey {
        let deviceID = UIDevice.current.identifierForVendor?.uuidString ?? "default"
        let keyData = Data((deviceID + String(describing: salt)).utf8)
        return SymmetricKey(data: SHA256.hash(data: keyData))
    }
}

// MARK: - 使用示例

extension APIConfig {
    /// 安全获取 News API Key
    static var secureNewsAPIKey: String {
        APIKeyObfuscator.getAPIKey(for: "news") ?? ""
    }
    
    /// 安全获取 Stock API Key
    static var secureStockAPIKey: String {
        APIKeyObfuscator.getAPIKey(for: "stock") ?? ""
    }
}
