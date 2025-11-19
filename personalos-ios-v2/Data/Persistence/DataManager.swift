import Foundation

/// 数据管理器 - 使用 UserDefaults 和本地存储
@MainActor
class DataManager {
    static let shared = DataManager()
    
    private let userDefaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    // MARK: - Save
    
    func save<T: Encodable>(_ model: T, forKey key: String) throws {
        let data = try encoder.encode(model)
        userDefaults.set(data, forKey: key)
    }
    
    // MARK: - Load
    
    func load<T: Decodable>(_ type: T.Type, forKey key: String) throws -> T? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try decoder.decode(T.self, from: data)
    }
    
    // MARK: - Delete
    
    func delete(forKey key: String) {
        userDefaults.removeObject(forKey: key)
    }
    
    // MARK: - Clear All
    
    func clearAll() {
        if let bundleID = Bundle.main.bundleIdentifier {
            userDefaults.removePersistentDomain(forName: bundleID)
        }
    }
}
