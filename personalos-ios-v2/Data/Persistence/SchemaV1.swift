import Foundation
import SwiftData

// MARK: - Data Models
/// 使用 SwiftData 持久化待办
@Model
final class TodoItem {
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var category: String
    var priority: Int

    init(title: String, createdAt: Date = .now, isCompleted: Bool = false, category: String = "Life", priority: Int = 1) {
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.category = category
        self.priority = priority
    }
}

@Model
final class HealthLog {
    var id: UUID
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
