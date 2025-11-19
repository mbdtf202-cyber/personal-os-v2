import Foundation
import SwiftData

// MARK: - SwiftData Schema V1
/// 使用 SwiftData 持久化的核心模型定义
@Model
final class TodoItem {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var category: String
    var priority: Int

    init(id: UUID = UUID(), title: String, createdAt: Date = .now, isCompleted: Bool = false, category: String = "Life", priority: Int = 1) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.category = category
        self.priority = priority
    }
}

@Model
final class HealthLog {
    @Attribute(.unique) var id: UUID
    var date: Date
    var sleepHours: Double
    var moodScore: Int
    var steps: Int
    var energyLevel: Int

    init(id: UUID = UUID(), date: Date = .now, sleepHours: Double = 0, moodScore: Int = 5, steps: Int = 0, energyLevel: Int = 50) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.moodScore = moodScore
        self.steps = steps
        self.energyLevel = energyLevel
    }
}

@Model
final class TradeRecord {
    @Attribute(.unique) var id: UUID
    var symbol: String
    var type: TradeType
    var price: Double
    var quantity: Double
    var assetType: AssetType
    var emotion: TradeEmotion
    var note: String
    var date: Date

    init(id: UUID = UUID(), symbol: String, type: TradeType, price: Double, quantity: Double, assetType: AssetType, emotion: TradeEmotion, note: String, date: Date = .now) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.price = price
        self.quantity = quantity
        self.assetType = assetType
        self.emotion = emotion
        self.note = note
        self.date = date
    }
}
