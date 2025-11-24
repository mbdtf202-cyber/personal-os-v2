import SwiftUI
import SwiftData

struct BookmarkedNewsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \NewsItem.date, order: .reverse) private var bookmarkedNews: [NewsItem]
    @State private var selectedArticleURL: IdentifiableURL?
    
    // ✅ Task 27: Add delete confirmation
    @State private var itemToDelete: NewsItem?
    @State private var showDeleteConfirmation = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    if bookmarkedNews.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 48))
                                .foregroundStyle(AppTheme.tertiaryText)
                            Text("No bookmarks yet")
                                .font(.headline)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text("Long press on any article to bookmark it")
                                .font(.caption)
                                .foregroundStyle(AppTheme.tertiaryText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 60)
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(bookmarkedNews) { item in
                                BookmarkedNewsCard(item: item)
                                    .onTapGesture {
                                        if let url = item.url {
                                            selectedArticleURL = IdentifiableURL(url: url)
                                            HapticsManager.shared.light()
                                        }
                                    }
                                    .contextMenu {
                                        if let url = item.url {
                                            Button(action: {
                                                UIPasteboard.general.string = url.absoluteString
                                                HapticsManager.shared.success()
                                            }) {
                                                Label("Copy Link", systemImage: "doc.on.doc")
                                            }
                                            
                                            Button(action: {
                                                shareArticle(url: url, title: item.title)
                                            }) {
                                                Label("Share", systemImage: "square.and.arrow.up")
                                            }
                                        }
                                        
                                        Button(role: .destructive, action: {
                                            // ✅ Task 27: Show confirmation dialog
                                            itemToDelete = item
                                            showDeleteConfirmation = true
                                        }) {
                                            Label("Remove Bookmark", systemImage: "bookmark.slash")
                                        }
                                    }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Bookmarks")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .confirmationDialog(
                "Remove Bookmark",
                isPresented: $showDeleteConfirmation,
                presenting: itemToDelete
            ) { item in
                Button("Remove", role: .destructive) {
                    removeBookmark(item)
                }
                Button("Cancel", role: .cancel) {
                    itemToDelete = nil
                }
            } message: { item in
                Text("Are you sure you want to remove '\(item.title)' from bookmarks?")
            }
            .fullScreenCover(item: $selectedArticleURL) { identifiableURL in
                SafariView(url: identifiableURL.url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func removeBookmark(_ item: NewsItem) {
        modelContext.delete(item)
        
        do {
            try modelContext.save()
            HapticsManager.shared.light()
            Logger.log("Bookmark removed: \(item.title)", category: Logger.general)
            
            // ✅ Task 27: Clear the item after successful deletion
            itemToDelete = nil
        } catch {
            // ✅ Task 27: Handle deletion failure
            ErrorHandler.shared.handle(error, context: "BookmarkedNewsView.removeBookmark")
            itemToDelete = nil
        }
    }
    
    private func shareArticle(url: URL, title: String) {
        let activityVC = UIActivityViewController(
            activityItems: [title, url],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            activityVC.popoverPresentationController?.sourceView = window
            rootVC.present(activityVC, animated: true)
        }
        
        HapticsManager.shared.light()
    }
}

struct BookmarkedNewsCard: View {
    let item: NewsItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Bookmark Icon
            Image(systemName: "bookmark.fill")
                .font(.title3)
                .foregroundStyle(AppTheme.almond)
                .frame(width: 40, height: 40)
                .background(AppTheme.almond.opacity(0.15))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
                
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Text(item.source)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    
                    Text("•")
                        .foregroundStyle(AppTheme.tertiaryText)
                    
                    Text(item.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}

#Preview {
    BookmarkedNewsView()
        .modelContainer(for: NewsItem.self, inMemory: true)
}
