import SwiftUI
import SwiftData

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
