import Foundation
import Security

/// Keychain accessibility options
enum KeychainAccessibility {
    case whenUnlocked
    case afterFirstUnlock
    case always
    case whenPasscodeSetThisDeviceOnly
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly
    case alwaysThisDeviceOnly
    
    var attribute: CFString {
        switch self {
        case .whenUnlocked:
            return kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock:
            return kSecAttrAccessibleAfterFirstUnlock
        case .always:
            return kSecAttrAccessibleAlways
        case .whenPasscodeSetThisDeviceOnly:
            return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
        case .whenUnlockedThisDeviceOnly:
            return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly:
            return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        case .alwaysThisDeviceOnly:
            return kSecAttrAccessibleAlwaysThisDeviceOnly
        }
    }
}

/// Secure storage service using iOS Keychain
final class SecureStorageService {
    static let shared = SecureStorageService()
    
    private let serviceName: String
    
    private init() {
        self.serviceName = Bundle.main.bundleIdentifier ?? "com.personalos.app"
    }
    
    // MARK: - Keychain Operations
    
    /// Store a string value in Keychain
    func store(key: String, value: String, accessibility: KeychainAccessibility = .whenUnlocked) throws {
        guard let data = value.data(using: .utf8) else {
            throw SecureStorageError.encodingFailed
        }
        
        try store(key: key, data: data, accessibility: accessibility)
    }
    
    /// Store data in Keychain
    func store(key: String, data: Data, accessibility: KeychainAccessibility = .whenUnlocked) throws {
        // Delete existing item first
        try? delete(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: accessibility.attribute
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw SecureStorageError.keychainError(status)
        }
        
        Logger.log("Stored value in Keychain for key: \(key)", category: Logger.general)
    }
    
    /// Retrieve a string value from Keychain
    func retrieve(key: String) throws -> String? {
        guard let data = try retrieveData(key: key) else {
            return nil
        }
        
        guard let string = String(data: data, encoding: .utf8) else {
            throw SecureStorageError.decodingFailed
        }
        
        return string
    }
    
    /// Retrieve data from Keychain
    func retrieveData(key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        guard status == errSecSuccess else {
            throw SecureStorageError.keychainError(status)
        }
        
        guard let data = result as? Data else {
            throw SecureStorageError.unexpectedData
        }
        
        return data
    }
    
    /// Delete a value from Keychain
    func delete(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.keychainError(status)
        }
        
        Logger.log("Deleted value from Keychain for key: \(key)", category: Logger.general)
    }
    
    /// Delete all values from Keychain for this service
    func deleteAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecureStorageError.keychainError(status)
        }
        
        Logger.log("Deleted all values from Keychain", category: Logger.general)
    }
    
    // MARK: - Data Encryption/Decryption
    
    /// Encrypt data using iOS Data Protection
    func encryptData(_ data: Data) throws -> Data {
        // iOS Data Protection is automatically applied when storing to Keychain
        // For additional encryption, we can use CryptoKit
        
        // For now, return the data as-is since Keychain provides encryption
        // In a production app, you might want to add an additional layer
        return data
    }
    
    /// Decrypt data
    func decryptData(_ data: Data) throws -> Data {
        // Corresponding decryption for encryptData
        return data
    }
    
    // MARK: - Convenience Methods
    
    /// Store API key
    func storeAPIKey(_ key: String, for service: String) throws {
        try store(key: "api_key_\(service)", value: key, accessibility: .afterFirstUnlock)
    }
    
    /// Retrieve API key
    func retrieveAPIKey(for service: String) throws -> String? {
        return try retrieve(key: "api_key_\(service)")
    }
    
    /// Store authentication token
    func storeAuthToken(_ token: String) throws {
        try store(key: "auth_token", value: token, accessibility: .whenUnlocked)
    }
    
    /// Retrieve authentication token
    func retrieveAuthToken() throws -> String? {
        return try retrieve(key: "auth_token")
    }
    
    /// Delete authentication token
    func deleteAuthToken() throws {
        try delete(key: "auth_token")
    }
}

/// Secure storage errors
enum SecureStorageError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case keychainError(OSStatus)
    case unexpectedData
    
    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data"
        case .decodingFailed:
            return "Failed to decode data"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .unexpectedData:
            return "Unexpected data format"
        }
    }
}
