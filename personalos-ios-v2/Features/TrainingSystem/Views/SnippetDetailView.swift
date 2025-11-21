import SwiftUI
import SwiftData

struct SnippetDetailView: View {
    @Bindable var snippet: CodeSnippet
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showDeleteAlert = false
    
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
                        
                        CodeBlockView(code: snippet.code, language: snippet.language)
                            .frame(maxWidth: .infinity, alignment: .leading)
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
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: copyCode) {
                        Label("Copy Code", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: shareSnippet) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(action: exportAsMarkdown) {
                        Label("Export as Markdown", systemImage: "arrow.down.doc")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { showDeleteAlert = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .alert("Delete Snippet?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteSnippet()
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }
    
    private func copyCode() {
        UIPasteboard.general.string = snippet.code
        HapticsManager.shared.success()
        Logger.log("Code copied to clipboard", category: Logger.general)
    }
    
    private func shareSnippet() {
        let text = """
        # \(snippet.title)
        
        **Language:** \(snippet.language)
        **Category:** \(snippet.category.rawValue)
        
        \(snippet.summary)
        
        ```\(snippet.language.lowercased())
        \(snippet.code)
        ```
        """
        
        let activityVC = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
        
        HapticsManager.shared.light()
        Logger.log("Snippet shared", category: Logger.general)
    }
    
    private func exportAsMarkdown() {
        let markdown = """
        # \(snippet.title)
        
        **Language:** \(snippet.language)  
        **Category:** \(snippet.category.rawValue)  
        **Date:** \(snippet.date.formatted(date: .long, time: .omitted))
        
        ## Description
        \(snippet.summary)
        
        ## Code
        ```\(snippet.language.lowercased())
        \(snippet.code)
        ```
        
        ---
        *Exported from Personal OS*
        """
        
        UIPasteboard.general.string = markdown
        HapticsManager.shared.success()
        Logger.log("Snippet exported as Markdown", category: Logger.general)
    }
    
    private func deleteSnippet() {
        Task {
            do {
                try await appDependency?.repositories.codeSnippet.delete(snippet)
                HapticsManager.shared.success()
                dismiss()
            } catch {
                ErrorHandler.shared.handle(error, context: "SnippetDetailView.deleteSnippet")
            }
        }
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
