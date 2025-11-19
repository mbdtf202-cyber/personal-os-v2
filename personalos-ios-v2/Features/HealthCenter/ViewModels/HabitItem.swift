import SwiftUI

struct HabitItem: Identifiable, Codable {
    let id: UUID
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
