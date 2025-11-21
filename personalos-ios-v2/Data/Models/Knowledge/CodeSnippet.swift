import SwiftUI
import SwiftData

@Model
final class CodeSnippet {
    var id: UUID
    var title: String
    var language: String
    var code: String
    var summary: String
    var categoryRaw: String
    var date: Date
    
    init(id: UUID = UUID(), title: String, language: String, code: String, summary: String, category: KnowledgeCategory, date: Date = Date()) {
        self.id = id
        self.title = title
        self.language = language
        self.code = code
        self.summary = summary
        self.categoryRaw = category.rawValue
        self.date = date
    }
    
    var category: KnowledgeCategory {
        get { KnowledgeCategory(rawValue: categoryRaw) ?? .swift }
        set { categoryRaw = newValue.rawValue }
    }
    
    static var defaultSnippets: [CodeSnippet] {
        [
            CodeSnippet(
                title: "Custom Glassmorphism Modifier",
                language: "Swift",
                code: """
struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .cornerRadius(20)
            .shadow(radius: 10)
    }
}
""",
                summary: "A reusable SwiftUI modifier for iOS 17 glass effects.",
                category: .swift
            ),
            CodeSnippet(
                title: "Docker Compose Setup",
                language: "YAML",
                code: """
version: '3'
services:
  web:
    build: .
    ports:
      - "5000:5000"
""",
                summary: "Quick setup for Python Flask apps.",
                category: .devops
            ),
            CodeSnippet(
                title: "Transformer Attention",
                language: "Python",
                code: """
def scaled_dot_product_attention(q, k, v, mask):
    matmul_qk = tf.matmul(q, k, transpose_b=True)
    dk = tf.cast(tf.shape(k)[-1], tf.float32)
    scaled_attention_logits = matmul_qk / tf.math.sqrt(dk)
""",
                summary: "Core logic for Self-Attention mechanism.",
                category: .ai
            )
        ]
    }
}

enum KnowledgeCategory: String, CaseIterable, Codable {
    case swift = "Swift"
    case python = "Python"
    case ai = "AI/ML"
    case devops = "DevOps"
    case web = "Web"
    case database = "Database"
    
    var color: Color {
        switch self {
        case .swift: return AppTheme.coral
        case .python: return AppTheme.mistBlue
        case .ai: return AppTheme.lavender
        case .devops: return AppTheme.almond
        case .web: return AppTheme.matcha
        case .database: return .indigo
        }
    }
    
    var icon: String {
        switch self {
        case .swift: return "swift"
        case .python: return "terminal.fill"
        case .ai: return "brain.head.profile"
        case .devops: return "server.rack"
        case .web: return "globe"
        case .database: return "cylinder.fill"
        }
    }
}
