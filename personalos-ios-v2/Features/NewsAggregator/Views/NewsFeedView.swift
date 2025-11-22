import SwiftUI
import SwiftData

struct NewsFeedView: View {
    @Environment(NewsService.self) private var newsService
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appDependency) private var appDependency
    @Query(sort: \NewsItem.date, order: .reverse) private var bookmarkedNews: [NewsItem]
    
    @State private var selectedCategory = "All"
    @State private var news: [NewsItem] = []
    @State private var selectedArticleURL: IdentifiableURL?
    @State private var readArticleIDs: Set<UUID> = []
    @State private var showRSSFeeds = false
    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var searchQuery = ""

    
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
    
    var filteredNews: [NewsItem] {
        if searchQuery.isEmpty {
            return news
        }
        return news.filter { item in
            item.title.localizedCaseInsensitiveContains(searchQuery) ||
            item.summary.localizedCaseInsensitiveContains(searchQuery)
        }
    }
    
    // Computed property for empty state message
    private var emptyStateMessage: String {
        if !searchQuery.isEmpty {
            return "No results found for '\(searchQuery)'"
        }
        if APIConfig.hasValidNewsAPIKey {
            return "No news available"
        }
        return "Configure News API key in Settings"
    }
    
    // Computed property for retry action
    private var retryAction: (() async -> Void)? {
        if searchQuery.isEmpty && APIConfig.hasValidNewsAPIKey {
            return refreshNews
        }
        return nil
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar (when active)
                    if showSearch {
                        searchBar
                    }
                    
                    // Category Filter (using NewsHeader component)
                    NewsHeader(
                        selectedCategory: $selectedCategory,
                        categories: categories,
                        onRefresh: refreshNews
                    )
                    
                    // News List
                    ScrollView(showsIndicators: false) {
                        if newsService.isLoading {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Loading latest news...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if filteredNews.isEmpty {
                            NewsEmptyState(
                                message: emptyStateMessage,
                                onRetry: retryAction
                            )
                        } else {
                            LazyVStack(spacing: 16) {
                                // Error Banner
                                if let error = newsService.error {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundStyle(AppTheme.coral)
                                        Text(error)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.secondaryText)
                                        Spacer()
                                        Button("Retry") {
                                            Task { await refreshNews() }
                                        }
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.mistBlue)
                                    }
                                    .padding()
                                    .background(AppTheme.coral.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
                                ForEach(filteredNews) { item in
                                    NewsCard(
                                        article: convertToNewsArticle(item),
                                        isBookmarked: bookmarkedNews.contains(where: { $0.id == item.id }),
                                        onBookmark: {
                                            bookmarkArticle(item)
                                        },
                                        onCreateTask: {
                                            createTaskFromArticle(item)
                                        }
                                    )
                                    .onTapGesture {
                                        openArticle(item)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }
                    }
                    .refreshable {
                        await refreshNews()
                    }
                }
            }
            .navigationTitle(L.News.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: toolbarContent)
            .sheet(isPresented: $showRSSFeeds) {
                RSSFeedsView(onLoadFeeds: { feeds in
                    Task {
                        await loadFromRSSFeeds(feeds)
                    }
                })
            }
            .sheet(isPresented: $showBookmarks) {
                BookmarkedNewsView()
            }
            .onAppear {
                Task {
                    if news.isEmpty {
                        if APIConfig.hasValidNewsAPIKey {
                            await refreshNews()
                        } else {
                            // Use mock data if no API key
                            news = mockNews
                        }
                    }
                }
            }
            .onChange(of: selectedCategory) { _, _ in
                handleCategoryChange()
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
        }
    }
    
    private func handleCategoryChange() {
        Task {
            if APIConfig.hasValidNewsAPIKey {
                await refreshNews()
            }
        }
    }
    
    private func loadFromRSSFeeds(_ feeds: [RSSFeed]) async {
        await newsService.fetchFromMultipleRSSFeeds(feeds: feeds)
        if !newsService.articles.isEmpty {
            news = newsService.articles.map { article in
                NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "No description available",
                    category: "RSS",
                    image: "antenna.radiowaves.left.and.right",
                    imageURL: article.urlToImage,
                    date: Date(),
                    url: URL(string: article.url)
                )
            }
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
        // Check if already bookmarked
        Task {
            do {
                if let existingBookmark = bookmarkedNews.first(where: { $0.id == item.id }) {
                    // Remove bookmark
                    try await appDependency?.repositories.news.delete(existingBookmark)
                    HapticsManager.shared.light()
                    Logger.log("Bookmark removed: \(item.title)", category: Logger.general)
                } else {
                    // Add bookmark
                    try await appDependency?.repositories.news.save(item)
                    HapticsManager.shared.success()
                    Logger.log("Article bookmarked: \(item.title)", category: Logger.general)
                }
            } catch {
                ErrorHandler.shared.handle(error, context: "NewsFeedView.bookmarkArticle")
            }
        }
    }
    
    private func createTaskFromArticle(_ item: NewsItem) {
        let task = TodoItem(
            title: "Read: \(item.title)",
            category: "Reading",
            priority: 1
        )
        Task {
            do {
                try await appDependency?.repositories.todo.save(task)
                HapticsManager.shared.success()
                Logger.log("Task created from article", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "NewsFeedView.createTaskFromArticle")
            }
        }
    }
    
    private func openArticle(_ item: NewsItem) {
        if let url = item.url {
            readArticleIDs.insert(item.id)
            selectedArticleURL = IdentifiableURL(url: url)
            HapticsManager.shared.light()
        }
    }
    
    private func convertToNewsArticle(_ item: NewsItem) -> NewsArticle {
        let dateFormatter = ISO8601DateFormatter()
        return NewsArticle(
            title: item.title,
            description: item.summary,
            url: item.url?.absoluteString ?? "",
            urlToImage: item.imageURL,
            publishedAt: dateFormatter.string(from: item.date),
            source: NewsArticle.NewsSource(name: item.source)
        )
    }
    
    @ToolbarContentBuilder
    private func toolbarContent() -> some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Menu {
                Button(action: { showRSSFeeds = true }) {
                    Label("RSS Feeds", systemImage: "antenna.radiowaves.left.and.right")
                }
                
                Button(action: { showBookmarks = true }) {
                    Label("Bookmarks (\(bookmarkedNews.count))", systemImage: "bookmark.fill")
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 20))
            }
        }
        
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button(action: { showSearch.toggle() }) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
            }
            
            Button {
                Task { await refreshNews() }
            } label: {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18))
            }
            .disabled(newsService.isLoading)
        }
    }
    
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.secondaryText)
            
            TextField("Search news...", text: $searchQuery)
                .textFieldStyle(.plain)
            
            if !searchQuery.isEmpty {
                Button(action: { searchQuery = "" }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.tertiaryText)
                }
            }
            
            Button("Cancel") {
                showSearch = false
                searchQuery = ""
            }
            .font(.subheadline)
            .foregroundStyle(AppTheme.mistBlue)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

}



#Preview {
    NewsFeedView()
        .modelContainer(for: NewsItem.self, inMemory: true)
}
