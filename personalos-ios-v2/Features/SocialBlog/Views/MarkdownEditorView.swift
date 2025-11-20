import SwiftUI

struct MarkdownEditorView: View {
    @Binding var post: SocialPost
    var onSave: ((SocialPost) -> Void)?
    @Environment(\.dismiss) var dismiss
    @State private var isPreviewMode = false
    @State private var showCopiedAlert = false
    @FocusState private var isContentFocused: Bool
    
    private var characterCount: Int {
        post.content.count
    }
    
    private var characterLimit: Int? {
        switch post.platform {
        case .twitter: return 280
        case .weibo: return 2000
        default: return nil
        }
    }
    
    private var isOverLimit: Bool {
        guard let limit = characterLimit else { return false }
        return characterCount > limit
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 1. Meta Info Bar
                HStack {
                    Picker("Platform", selection: $post.platform) {
                        ForEach(SocialPlatform.allCases, id: \.self) { p in
                            Label(p.rawValue, systemImage: p.icon).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(post.platform.color)
                    
                    Spacer()
                    
                    DatePicker("", selection: $post.date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                }
                .padding()
                .background(.ultraThinMaterial)
                
                Divider()
                
                // 2. Title Input
                TextField("Post Title...", text: $post.title)
                    .font(.title2.bold())
                    .padding()
                    .submitLabel(.next)
                
                Divider()
                
                // 3. Content Editor
                if isPreviewMode {
                    ScrollView {
                        Text(post.content)
                            .font(.body)
                            .lineSpacing(6)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                    }
                } else {
                    VStack(spacing: 0) {
                        TextEditor(text: $post.content)
                            .font(.body)
                            .lineSpacing(6)
                            .padding()
                            .scrollContentBackground(.hidden)
                            .background(AppTheme.background)
                            .focused($isContentFocused)
                        
                        // Markdown Toolbar
                        if isContentFocused {
                            markdownToolbar
                        }
                        
                        // Character Count
                        characterCountBar
                    }
                }
            }
            .navigationTitle(post.status.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        onSave?(post)
                        dismiss()
                    }
                    .disabled(isOverLimit)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Menu {
                        Button(action: { isPreviewMode.toggle() }) {
                            Label(isPreviewMode ? "Edit" : "Preview", systemImage: isPreviewMode ? "pencil" : "eye")
                        }
                        
                        Button(action: copyToClipboard) {
                            Label("Copy Content", systemImage: "doc.on.doc")
                        }
                        
                        Button(action: shareContent) {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        
                        Divider()
                        
                        Menu("Change Status") {
                            ForEach([PostStatus.idea, .draft, .scheduled, .published], id: \.self) { status in
                                Button(action: { post.status = status }) {
                                    Label(status.rawValue, systemImage: status == post.status ? "checkmark" : "")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Copied!", isPresented: $showCopiedAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Content copied to clipboard")
            }
        }
    }
    
    // MARK: - Components
    
    private var markdownToolbar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ToolbarButton(icon: "number", label: "H1") {
                    insertMarkdown("# ")
                }
                ToolbarButton(icon: "bold", label: "Bold") {
                    insertMarkdown("**", suffix: "**")
                }
                ToolbarButton(icon: "italic", label: "Italic") {
                    insertMarkdown("*", suffix: "*")
                }
                ToolbarButton(icon: "link", label: "Link") {
                    insertMarkdown("[", suffix: "](url)")
                }
                ToolbarButton(icon: "list.bullet", label: "List") {
                    insertMarkdown("- ")
                }
                ToolbarButton(icon: "photo", label: "Image") {
                    insertMarkdown("![alt](", suffix: ")")
                }
                ToolbarButton(icon: "chevron.left.forwardslash.chevron.right", label: "Code") {
                    insertMarkdown("`", suffix: "`")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(.ultraThinMaterial)
    }
    
    private var characterCountBar: some View {
        HStack {
            if let limit = characterLimit {
                Text("\(characterCount) / \(limit)")
                    .font(.caption)
                    .foregroundStyle(isOverLimit ? AppTheme.coral : AppTheme.secondaryText)
                    .fontWeight(isOverLimit ? .semibold : .regular)
                
                if isOverLimit {
                    Text("• Over limit by \(characterCount - limit)")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.coral)
                }
            } else {
                Text("\(characterCount) characters")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Button(action: copyToClipboard) {
                Label("Copy", systemImage: "doc.on.doc")
                    .font(.caption)
                    .foregroundStyle(AppTheme.mistBlue)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.5))
    }
    
    // MARK: - Actions
    
    private func insertMarkdown(_ prefix: String, suffix: String = "") {
        let cursorPosition = post.content.count
        post.content.insert(contentsOf: prefix, at: post.content.index(post.content.startIndex, offsetBy: cursorPosition))
        if !suffix.isEmpty {
            post.content.insert(contentsOf: suffix, at: post.content.index(post.content.startIndex, offsetBy: cursorPosition + prefix.count))
        }
        HapticsManager.shared.light()
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = post.content
        showCopiedAlert = true
        HapticsManager.shared.success()
    }
    
    private func shareContent() {
        let activityVC = UIActivityViewController(
            activityItems: [post.content],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

struct ToolbarButton: View {
    let icon: String
    let label: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(AppTheme.primaryText)
            .frame(width: 50)
        }
    }
}

#Preview {
    MarkdownEditorView(post: .constant(
        SocialPost(title: "Test", platform: .twitter, status: .draft, date: Date(), content: "Test content", views: 0, likes: 0)
    ), onSave: nil)
}
