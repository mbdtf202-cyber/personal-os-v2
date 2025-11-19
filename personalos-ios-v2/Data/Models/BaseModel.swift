import Foundation

// 基础模型协议
protocol BaseModel: Identifiable, Codable {
    var id: String { get }
    var createdAt: Date { get set }
    var updatedAt: Date { get set }
}
