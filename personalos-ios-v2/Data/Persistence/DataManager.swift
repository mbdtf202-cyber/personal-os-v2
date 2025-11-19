import Foundation
import SwiftData

/// 数据管理器 - 封装 SwiftData 的常用操作
@MainActor
final class DataManager {
    static let shared = DataManager()

    private init() {}

    /// 通用的查询方法
    func fetch<T: PersistentModel>(_ descriptor: FetchDescriptor<T>, in context: ModelContext) throws -> [T] {
        try context.fetch(descriptor)
    }

    /// 插入并保存
    func insert<T: PersistentModel>(_ model: T, in context: ModelContext) throws {
        context.insert(model)
        try context.save()
    }

    /// 删除模型
    func delete<T: PersistentModel>(_ model: T, in context: ModelContext) throws {
        context.delete(model)
        try context.save()
    }
}
