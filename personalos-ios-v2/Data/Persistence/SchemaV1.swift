import SwiftData
import Foundation

// ⚠️ 升级：引入 SwiftData，将 struct 改为 @Model class
class SchemaV1 {
    @Model
    final class TradeRecord {
        var id: UUID
        var symbol: String
        var type: String // "Buy" or "Sell"
        var price: Double
        var quantity: Double
        var date: Date
        var note: String

        init(symbol: String, type: String, price: Double, quantity: Double, note: String = "") {
            self.id = UUID()
            self.symbol = symbol
            self.type = type
            self.price = price
            self.quantity = quantity
            self.date = Date()
            self.note = note
        }
    }

    @Model
    final class TodoItem {
        var id: UUID
        var title: String
        var isCompleted: Bool
        var createdAt: Date
        var category: String
        var priority: Int

        init(title: String, category: String = "Life", priority: Int = 1) {
            self.id = UUID()
            self.title = title
            self.isCompleted = false
            self.createdAt = Date()
            self.category = category
            self.priority = priority
        }
    }
}
