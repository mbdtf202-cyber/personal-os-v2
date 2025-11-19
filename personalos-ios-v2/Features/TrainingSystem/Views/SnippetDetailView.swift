import SwiftUI

struct SnippetDetailView: View {
    let snippet: CodeSnippet
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(snippet.language)
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(snippet.category.color.opacity(0.2))
                                .foregroundStyle(snippet.category.color)
                                .cornerRadius(8)
                            Spacer()
                            Text(snippet.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(AppTheme.secondaryText)
                        }
                        Text(snippet.title)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(AppTheme.primaryText)
                        Text(snippet.summary)
                            .font(.body)
                            .foregroundStyle(AppTheme.secondaryText)
                    }
                    .padding(.horizontal, 20)
                    
                    // Code Block
                    VStack(alignment: .leading, spacing: 0) {
                        HStack {
                            Circle().fill(Color(hex: "FF5F56")).frame(width: 12)
                            Circle().fill(Color(hex: "FFBD2E")).frame(width: 12)
                            Circle().fill(Color(hex: "27C93F")).frame(width: 12)
                            Spacer()
                            Image(systemName: "doc.on.doc")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                        .padding()
                        .background(Color(hex: "2D2D2D"))
                        
                        Text(snippet.code)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(Color(hex: "E0E0E0"))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(hex: "1E1E1E"))
                    }
                    .cornerRadius(16)
                    .padding(.horizontal, 20)
                    .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
                    
                    // Related Notes
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Related Notes")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        HStack {
                            Image(systemName: "link")
                            Text("Reference: Apple Developer Documentation")
                                .font(.subheadline)
                                .underline()
                        }
                        .foregroundStyle(AppTheme.mistBlue)
                    }
                    .padding(20)
                }
                .padding(.top, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SnippetDetailView(
            snippet: CodeSnippet(
                title: "Test Snippet",
                language: "Swift",
                code: "print(\"Hello\")",
                summary: "A test snippet",
                category: .swift,
                date: Date()
            )
        )
    }
}
