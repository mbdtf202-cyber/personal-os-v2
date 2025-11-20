import SwiftUI
import SwiftData

struct AddSnippetView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var language = "Swift"
    @State private var code = ""
    @State private var summary = ""
    @State private var category: KnowledgeCategory = .swift
    
    let languages = ["Swift", "Python", "JavaScript", "TypeScript", "Go", "Rust", "Java", "Kotlin", "C++", "SQL", "YAML", "JSON"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Basic Info")) {
                    TextField("Title", text: $title)
                    
                    Picker("Language", selection: $language) {
                        ForEach(languages, id: \.self) { lang in
                            Text(lang).tag(lang)
                        }
                    }
                    
                    Picker("Category", selection: $category) {
                        ForEach(KnowledgeCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon).tag(cat)
                        }
                    }
                }
                
                Section(header: Text("Summary")) {
                    TextEditor(text: $summary)
                        .frame(height: 60)
                }
                
                Section(header: Text("Code")) {
                    TextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 200)
                }
            }
            .navigationTitle("Add Snippet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSnippet()
                    }
                    .disabled(title.isEmpty || code.isEmpty)
                }
            }
        }
    }
    
    private func saveSnippet() {
        let snippet = CodeSnippet(
            title: title,
            language: language,
            code: code,
            summary: summary.isEmpty ? "No description" : summary,
            category: category
        )
        
        modelContext.insert(snippet)
        try? modelContext.save()
        
        HapticsManager.shared.success()
        Logger.log("Code snippet saved: \(title)", category: Logger.general)
        
        dismiss()
    }
}

#Preview {
    AddSnippetView()
}
