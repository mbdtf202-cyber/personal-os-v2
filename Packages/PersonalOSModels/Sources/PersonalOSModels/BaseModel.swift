import Foundation
import SwiftData

/// ✅ MODULARIZATION: 基础模型协议
/// 所有 SwiftData 模型的基础协议
public protocol BaseModelProtocol: PersistentModel {
    var id: UUID { get set }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}

/// 默认实现
public extension BaseModelProtocol {
    func updateTimestamp() {
        updatedAt = Date()
    }
}
