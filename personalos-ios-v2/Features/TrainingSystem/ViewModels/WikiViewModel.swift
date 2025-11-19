import SwiftUI
import Observation

@Observable
class WikiViewModel {
    var searchText: String = ""
    var selectedCategory: KnowledgeCategory? = nil
    
    var snippets: [CodeSnippet] = [
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
            category: .swift,
            date: Date()
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
            category: .devops,
            date: Date().addingTimeInterval(-86400)
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
            category: .ai,
            date: Date().addingTimeInterval(-172800)
        )
    ]
    
    var filteredSnippets: [CodeSnippet] {
        snippets.filter { snippet in
            let matchCategory = selectedCategory == nil || snippet.category == selectedCategory
            let matchSearch = searchText.isEmpty || snippet.title.localizedCaseInsensitiveContains(searchText)
            return matchCategory && matchSearch
        }
    }
}
