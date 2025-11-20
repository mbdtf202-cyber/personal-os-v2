import SwiftUI
import SwiftData

struct QuickNoteOverlay: View {
    @Binding var isPresented: Bool
    @State private var noteText: String = ""
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation { isPresented = false }
                }
            
            VStack {
                Spacer()
                
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Quick Note")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryText)
                        Spacer()
                        Button("Save") {
                            saveNote()
                            withAnimation { isPresented = false }
                        }
                        .fontWeight(.bold)
                        .foregroundStyle(AppTheme.mistBlue)
                        .disabled(noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                    
                    TextEditor(text: $noteText)
                        .frame(height: 120)
                        .focused($isFocused)
                        .scrollContentBackground(.hidden)
                        .padding(12)
                        .background(AppTheme.background)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppTheme.border, lineWidth: 1))
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            // TODO: Implement document scanning
                            HapticsManager.shared.light()
                        }) {
                            Label("Scan", systemImage: "doc.viewfinder")
                        }
                        Button(action: {
                            // TODO: Implement image picker
                            HapticsManager.shared.light()
                        }) {
                            Label("Image", systemImage: "photo")
                        }
                        Spacer()
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                }
                .padding(24)
                .background(Color.white)
                .cornerRadius(24)
                .shadow(radius: 20)
                .padding()
                .padding(.bottom, 20)
            }
        }
        .onAppear { isFocused = true }
    }
    
    private func saveNote() {
        let trimmedText = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { return }
        
        // Save as a todo item for now
        let todo = TodoItem(
            title: trimmedText.components(separatedBy: .newlines).first ?? trimmedText,
            category: "Note",
            priority: 1
        )
        
        modelContext.insert(todo)
        try? modelContext.save()
        
        HapticsManager.shared.success()
        Logger.log("Quick note saved", category: Logger.general)
    }
}

#Preview {
    QuickNoteOverlay(isPresented: .constant(true))
}
