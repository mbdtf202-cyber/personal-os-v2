import SwiftUI

struct MarkdownEditorView: View {
    @Binding var post: SocialPost
    var onSave: ((SocialPost) -> Void)?
    @Environment(\.dismiss) var dismiss
    @State private var isPreviewMode = false
    
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
                    TextEditor(text: $post.content)
                        .font(.body)
                        .lineSpacing(6)
                        .padding()
                        .scrollContentBackground(.hidden)
                        .background(AppTheme.background)
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
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button(action: { isPreviewMode.toggle() }) {
                        Image(systemName: isPreviewMode ? "eye.slash" : "eye")
                    }
                }
            }
        }
    }
}

#Preview {
    MarkdownEditorView(post: .constant(
        SocialPost(title: "Test", platform: .twitter, status: .draft, date: Date(), content: "Test content", views: 0, likes: 0)
    ), onSave: nil)
}
