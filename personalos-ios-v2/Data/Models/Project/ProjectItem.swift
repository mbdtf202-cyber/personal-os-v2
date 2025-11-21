import SwiftUI
import SwiftData

@Model
final class ProjectItem {
    var id: UUID
    var name: String
    var details: String
    var language: String
    var stars: Int
    var status: ProjectStatus
    var progress: Double

    init(id: UUID = UUID(), name: String, details: String, language: String, stars: Int, status: ProjectStatus, progress: Double) {
        self.id = id
        self.name = name
        self.details = details
        self.language = language
        self.stars = stars
        self.status = status
        self.progress = progress
    }
}

enum ProjectStatus: String, CaseIterable, Codable {
    case active = "Active"
    case idea = "Idea"
    case done = "Done"
    
    var color: Color {
        switch self {
        case .active: return AppTheme.mistBlue
        case .idea: return AppTheme.almond
        case .done: return AppTheme.matcha
        }
    }
}
