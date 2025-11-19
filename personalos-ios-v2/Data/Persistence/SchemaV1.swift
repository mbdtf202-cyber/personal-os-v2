import Foundation

// MARK: - Schema Definition (使用 Codable 而不是 @Model)

class SchemaV1 {
    // 1. 待办事项
    struct TodoItem: Identifiable, Codable {
        var id: String
        var title: String
        var createdAt: Date = Date()
        var isCompleted: Bool = false
        var category: String = "Life"
        var priority: Int = 1
        
        init(title: String, category: String = "Life", priority: Int = 1) {
            self.id = UUID().uuidString
            self.title = title
            self.category = category
            self.priority = priority
        }
    }
    
    // 2. 健康日志
    struct HealthLog: Identifiable, Codable {
        var id: String
        var date: Date = Date()
        var sleepHours: Double = 0
        var moodScore: Int = 5
        var steps: Int = 0
        var energyLevel: Int = 50
        
        init(date: Date = Date()) {
            self.id = UUID().uuidString
            self.date = date
        }
    }
    
    // 3. 交易记录
    struct TradeRecord: Identifiable, Codable {
        var id: String
        var symbol: String
        var type: String
        var price: Double
        var quantity: Double
        var date: Date = Date()
        var note: String = ""
        
        init(symbol: String, type: String, price: Double, quantity: Double) {
            self.id = UUID().uuidString
            self.symbol = symbol
            self.type = type
            self.price = price
            self.quantity = quantity
        }
    }
}
