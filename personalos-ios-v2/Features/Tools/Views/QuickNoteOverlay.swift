import SwiftUI
import SwiftData

struct QuickNoteOverlay: View {
    @Binding var isPresented: Bool
    @State private var noteText: String = ""
    @State private var saveAsPost: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependency) private var appDependency
    
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
                    
                    // Save options
                    HStack(spacing: 12) {
                        Button(action: { saveAsPost.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: saveAsPost ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(saveAsPost ? AppTheme.lavender : AppTheme.secondaryText)
                                Text("Save as Social Post")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.primaryText)
                            }
                        }
                        Spacer()
                    }
                    
                    Divider()
                    
                    HStack(spacing: 20) {
                        Text(saveAsPost ? "Will be saved to Social tab" : "Will be saved as Task")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.secondaryText)
                        Spacer()
                    }
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
        
        if saveAsPost {
            // Save as Social Post (Idea status)
            let title = trimmedText.components(separatedBy: .newlines).first ?? trimmedText
            let post = SocialPost(
                title: title,
                platform: .blog,
                status: .idea,
                date: Date(),
                content: trimmedText,
                views: 0,
                likes: 0
            )
            Task {
                do {
                    try await appDependency!.repositories.socialPost.save(post)
                    Logger.log("Quick note saved as Social Post", category: Logger.general)
                    HapticsManager.shared.success()
                } catch {
                    ErrorHandler.shared.handle(error, context: "QuickNoteOverlay.saveNote")
                }
            }
        } else {
            // Save as Todo Item
            let title = trimmedText.components(separatedBy: .newlines).first ?? trimmedText
            let todo = TodoItem(
                title: title,
                category: "Note",
                priority: 1
            )
            Task {
                do {
                    try await appDependency!.repositories.todo.save(todo)
                    Logger.log("Quick note saved as Task", category: Logger.general)
                    HapticsManager.shared.success()
                } catch {
                    ErrorHandler.shared.handle(error, context: "QuickNoteOverlay.saveNote")
                }
            }
        }
    }
}

#Preview {
    QuickNoteOverlay(isPresented: .constant(true))
}
