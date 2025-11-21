import SwiftUI
import SwiftData

@Model
final class HabitItem {
    var id: UUID
    var title: String
    var icon: String
    var isCompleted: Bool
    var streak: Int
    
    init(id: UUID = UUID(), title: String, icon: String, isCompleted: Bool = false, streak: Int = 0) {
        self.id = id
        self.title = title
        self.icon = icon
        self.isCompleted = isCompleted
        self.streak = streak
    }
    
    var color: Color {
        switch icon {
        case "figure.run": return AppTheme.coral
        case "book.fill": return AppTheme.lavender
        case "brain.head.profile": return AppTheme.mistBlue
        case "drop.fill": return AppTheme.mistBlue
        default: return AppTheme.matcha
        }
    }
    
    static var defaultHabits: [HabitItem] {
        [
            HabitItem(title: "Morning Exercise", icon: "figure.run", streak: 5),
            HabitItem(title: "Read 30 min", icon: "book.fill", streak: 3),
            HabitItem(title: "Meditation", icon: "brain.head.profile", streak: 7),
            HabitItem(title: "Drink Water", icon: "drop.fill", streak: 12)
        ]
    }
}
