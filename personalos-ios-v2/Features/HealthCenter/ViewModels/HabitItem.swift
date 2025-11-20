import SwiftUI
import SwiftData
import Combine

@Model
final class HabitItem {
    var id: UUID
    var icon: String
    var title: String
    var colorHex: String
    var isCompleted: Bool = false
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    init(id: UUID = UUID(), icon: String, title: String, color: Color, isCompleted: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.colorHex = color.toHex()
        self.isCompleted = isCompleted
    }
}

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "89C4F4" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}

extension HabitItem {
    static var defaultHabits: [HabitItem] {
        [
            HabitItem(icon: "drop.fill", title: "Drink 2L Water", color: AppTheme.mistBlue),
            HabitItem(icon: "book.fill", title: "Read 30 mins", color: AppTheme.lavender),
            HabitItem(icon: "figure.mind.and.body", title: "Meditation", color: AppTheme.matcha),
            HabitItem(icon: "moon.stars.fill", title: "Sleep Early", color: AppTheme.primaryText)
        ]
    }
}
