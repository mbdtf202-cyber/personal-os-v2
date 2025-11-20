import SwiftUI
import SwiftData

struct NewsFeedView: View {
    @Environment(NewsService.self) private var newsService
    @Environment(\.modelContext) private var modelContext
    @State private var selectedCategory = "All"
    @State private var news: [NewsItem] = []
    @State private var showError = false
    @State private var selectedArticleURL: IdentifiableURL?
    @State private var readArticleIDs: Set<UUID> = []
    @State private var showRSSFeeds = false
    @State private var showBookmarks = false
    
    let mockNews: [NewsItem] = [
        NewsItem(
            source: "The Verge",
            title: "Apple announces new AI features for iOS 18",
            summary: "Siri gets a massive upgrade with LLM capabilities...",
            category: "Tech",
            image: "apple.logo",
            date: Date(),
            url: nil
        ),
        NewsItem(
            source: "CoinDesk",
            title: "Bitcoin breaks $70k resistance level",
            summary: "Market sentiment remains high as ETFs see inflow...",
            category: "Crypto",
            image: "bitcoinsign.circle.fill",
            date: Date().addingTimeInterval(-3600),
            url: nil
        ),
        NewsItem(
            source: "HackerNews",
            title: "Show HN: Personal OS built with SwiftUI",
            summary: "A complete operating system for your life...",
            category: "Dev",
            image: "terminal.fill",
            date: Date().addingTimeInterval(-7200),
            url: nil
        )
    ]
    
    let categories = ["All", "Tech", "AI", "Crypto", "Dev", "Design"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { cat in
                                Button(action: { selectedCategory = cat }) {
                                    Text(cat)
                                        .font(.subheadline)
                                        .fontWeight(selectedCategory == cat ? .bold : .medium)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedCategory == cat ? AppTheme.primaryText : Color.white)
                                        .foregroundStyle(selectedCategory == cat ? .white : AppTheme.primaryText)
                                        .clipShape(Capsule())
                                        .shadow(color: AppTheme.shadow, radius: 4, y: 2)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    // News List
                    ScrollView(showsIndicators: false) {
                        if newsService.isLoading {
                            LoadingView(message: "Loading news...")
                        } else {
                            LazyVStack(spacing: 20) {
                                // Error Banner
                                if let error = newsService.error {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(AppTheme.coral)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Failed to load news")
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                            Text(error)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        Spacer()
                                        Button("Retry") {
                                            Task { await refreshNews() }
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(AppTheme.mistBlue)
                                    }
                                    .padding()
                                    .background(AppTheme.coral.opacity(0.1))
                                    .cornerRadius(12)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 10)
                                }
                                
                                ForEach(news) { item in
                                    NewsCard(item: item, isRead: readArticleIDs.contains(item.id))
                                        .onTapGesture {
                                            if let url = item.url {
                                                readArticleIDs.insert(item.id)
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
                                                
                                                Button(action: {
                                                    bookmarkArticle(item)
                                                }) {
                                                    Label("Bookmark", systemImage: "bookmark")
                                                }
                                                
                                                Button(action: {
                                                    createTaskFromArticle(item)
                                                }) {
                                                    Label("Create Task", systemImage: "checkmark.circle")
                                                }
                                            }
                                        }
                                }
                            }
                            .padding(20)
                        }
                    }
                    .refreshable {
                        await refreshNews()
                    }
                }
            }
            .navigationTitle("Briefing")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Button(action: { showRSSFeeds = true }) {
                            Label("RSS Feeds", systemImage: "antenna.radiowaves.left.and.right")
                        }
                        
                        Button(action: { showBookmarks = true }) {
                            Label("Bookmarks", systemImage: "bookmark")
                        }
                    } label: {
                        Image(systemName: "line.3.horizontal")
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { Task { await refreshNews() } }) {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(newsService.isLoading)
                    .accessibilityLabel("Refresh News")
                }
            }
            .sheet(isPresented: $showRSSFeeds) {
                RSSFeedsView()
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarkedNewsView()
            }
            .onAppear {
                if news.isEmpty {
                    news = mockNews
                }
            }
            .fullScreenCover(item: $selectedArticleURL) { identifiableURL in
                SafariView(url: identifiableURL.url)
                    .ignoresSafeArea()
            }
        }
    }
    
    private func refreshNews() async {
        await newsService.fetchTopHeadlines(category: selectedCategory.lowercased())
        if !newsService.articles.isEmpty {
            news = newsService.articles.map { article in
                NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "",
                    category: selectedCategory,
                    image: "newspaper.fill",
                    imageURL: article.urlToImage,
                    date: Date(),
                    url: URL(string: article.url)
                )
            }
        } else if newsService.error == nil && !APIConfig.hasValidNewsAPIKey {
            showError = true
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
    
    private func bookmarkArticle(_ item: NewsItem) {
        // Save to SwiftData
        modelContext.insert(item)
        try? modelContext.save()
        HapticsManager.shared.success()
        Logger.log("Article bookmarked: \(item.title)", category: Logger.general)
    }
    
    private func createTaskFromArticle(_ item: NewsItem) {
        let task = TodoItem(
            title: "Read: \(item.title)",
            category: "Reading",
            priority: 1
        )
        modelContext.insert(task)
        try? modelContext.save()
        HapticsManager.shared.success()
        Logger.log("Task created from article", category: Logger.general)
    }
}

struct NewsCard: View {
    let item: NewsItem
    var isRead: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Image Header
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                CachedAsyncImage(url: imageURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 160)
                        .clipped()
                        .cornerRadius(12)
                } placeholder: {
                    placeholderImage
                }
            }
            
            // Header
            HStack {
                Image(systemName: item.image)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mistBlue)
                    .frame(width: 24, height: 24)
                    .background(AppTheme.mistBlue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(item.source)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.secondaryText)
                
                Spacer()
                
                Text(item.date.formatted(date: .omitted, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            // Content
            Text(item.title)
                .font(.headline)
                .foregroundStyle(isRead ? AppTheme.secondaryText : AppTheme.primaryText)
                .lineLimit(2)
            
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(3)
            
            // Actions
            HStack {
                Label(item.category, systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.almond)
                
                Spacer()
                
                Button(action: {
                    // TODO: Implement bookmark functionality
                    HapticsManager.shared.light()
                }) {
                    Image(systemName: "bookmark")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primaryText)
                }
                
                Button(action: {
                    if let url = item.url {
                        shareArticle(url: url, title: item.title)
                    }
                }) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            .padding(.top, 8)
        }
        .glassCard()
    }
    
    private var placeholderImage: some View {
        ZStack {
            Color.gray.opacity(0.2)
            Image(systemName: "photo")
                .font(.largeTitle)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(height: 160)
        .cornerRadius(12)
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

#Preview {
    NewsFeedView()
}
