import SwiftUI

struct CodeSnippet: Identifiable {
    let id = UUID()
    var title: String
    var language: String
    var code: String
    var summary: String
    var category: KnowledgeCategory
    var date: Date
    
    var lines: Int {
        code.components(separatedBy: .newlines).count
    }
}

enum KnowledgeCategory: String, CaseIterable {
    case swift = "SwiftUI"
    case backend = "Backend"
    case ai = "AI & ML"
    case devops = "DevOps"
    case design = "Design"
    
    var color: Color {
        switch self {
        case .swift: return Color(hex: "F05138")
        case .backend: return Color(hex: "61DAFB")
        case .ai: return Color(hex: "9B59B6")
        case .devops: return Color(hex: "2ECC71")
        case .design: return Color(hex: "E91E63")
        }
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .backend: return "server.rack"
        case .ai: return "brain.head.profile"
        case .devops: return "terminal.fill"
        case .design: return "paintbrush.pointed.fill"
        }
    }
}
