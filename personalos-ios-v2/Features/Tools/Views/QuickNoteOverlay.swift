import SwiftUI
import SwiftData

struct QuickNoteOverlay: View {
    @Binding var isPresented: Bool
    @State private var noteText: String = ""
    @State private var saveAsPost: Bool = false
    @FocusState private var isFocused: Bool
    @Environment(\.appDependency) private var appDependency
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    private var isValid: Bool {
        !noteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        noteText.count <= 1000
    }
    
    private var characterCount: Int {
        noteText.count
    }
    
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
                        if isSaving {
                            ProgressView()
                                .tint(AppTheme.mistBlue)
                        } else {
                            Button("Save") {
                                saveNote()
                            }
                            .fontWeight(.bold)
                            .foregroundStyle(isValid ? AppTheme.mistBlue : AppTheme.tertiaryText)
                            .disabled(!isValid)
                        }
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
                        Text("\(characterCount)/1000")
                            .font(.caption2)
                            .foregroundStyle(characterCount > 1000 ? AppTheme.coral : AppTheme.tertiaryText)
                    }
                    
                    if showError {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(AppTheme.coral)
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundStyle(AppTheme.coral)
                        }
                        .padding(.top, 4)
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
        
        guard isValid else {
            showError = true
            errorMessage = trimmedText.isEmpty ? "Note cannot be empty" : "Note is too long (max 1000 characters)"
            HapticsManager.shared.error()
            return
        }
        
        isSaving = true
        showError = false
        
        Task {
            do {
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
                    try await appDependency?.repositories.socialPost.save(post)
                    Logger.log("Quick note saved as Social Post", category: Logger.general)
                } else {
                    // Save as Todo Item
                    let title = trimmedText.components(separatedBy: .newlines).first ?? trimmedText
                    let todo = TodoItem(
                        title: title,
                        category: "Note",
                        priority: 1
                    )
                    try await appDependency?.repositories.todo.save(todo)
                    Logger.log("Quick note saved as Task", category: Logger.general)
                }
                
                await MainActor.run {
                    HapticsManager.shared.success()
                    withAnimation { isPresented = false }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    showError = true
                    errorMessage = "Failed to save note. Please try again."
                    HapticsManager.shared.error()
                }
                ErrorHandler.shared.handle(error, context: "QuickNoteOverlay.saveNote")
            }
        }
    }
}

#Preview {
    QuickNoteOverlay(isPresented: .constant(true))
}
