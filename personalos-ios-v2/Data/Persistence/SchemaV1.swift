import Foundation

// MARK: - Data Models
/// 使用 UserDefaults 持久化的核心模型定义

struct TodoItem: Identifiable, Codable {
    let id: String
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var category: String
    var priority: Int

    init(id: String = UUID().uuidString, title: String, createdAt: Date = .now, isCompleted: Bool = false, category: String = "Life", priority: Int = 1) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.category = category
        self.priority = priority
    }
}

struct HealthLog: Identifiable, Codable {
    let id: String
    var date: Date
    var sleepHours: Double
    var moodScore: Int
    var steps: Int
    var energyLevel: Int

    init(id: String = UUID().uuidString, date: Date = .now, sleepHours: Double = 0, moodScore: Int = 5, steps: Int = 0, energyLevel: Int = 50) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.moodScore = moodScore
        self.steps = steps
        self.energyLevel = energyLevel
    }
}
