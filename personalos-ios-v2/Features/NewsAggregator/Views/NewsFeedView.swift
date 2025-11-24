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
    @State private var searchTask: Task<Void, Never>?
    @State private var searchResults: [NewsItem] = []
    @State private var isSearching = false
    
    // ✅ Task 26: Track bookmark and task operations to prevent duplicates
    @State private var bookmarkOperations: Set<UUID> = []
    @State private var taskOperations: Set<UUID> = []

    
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
        // ✅ Task 25: Use search results when searching
        if !searchQuery.isEmpty && !searchResults.isEmpty {
            return searchResults
        }
        if searchQuery.isEmpty {
            return news
        }
        // Fallback to local filtering
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
                        if newsService.isLoading || newsService.isParsingNews {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text(newsService.isParsingNews ? "Parsing news..." : "Loading latest news...")
                                    .font(.subheadline)
                                    .foregroundStyle(AppTheme.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                        } else if isSearching {
                            VStack(spacing: 16) {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Searching...")
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
                                // ✅ P0 Fix: Data source banner (Requirement 14.4)
                                if newsService.currentDataSource != .real {
                                    HStack {
                                        Image(systemName: "info.circle.fill")
                                            .foregroundStyle(newsService.currentDataSource == .demo ? .orange : .gray)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(newsService.currentDataSource.displayName)
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                            Text("Configure News API key in Settings for live data")
                                                .font(.caption2)
                                                .foregroundStyle(AppTheme.secondaryText)
                                        }
                                        Spacer()
                                    }
                                    .padding()
                                    .background(newsService.currentDataSource == .demo ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                                    .cornerRadius(12)
                                }
                                
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
                                        isBookmarked: bookmarkedNews.contains(where: { $0.canonicalID == item.canonicalID }), // ✅ Use canonical ID
                                        dataSource: item.dataSourceType,
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
                                    // ✅ P2 Fix: Long press context menu
                                    .contextMenu {
                                        Button {
                                            openArticle(item)
                                        } label: {
                                            Label("Open Article", systemImage: "safari")
                                        }
                                        
                                        Button {
                                            bookmarkArticle(item)
                                        } label: {
                                            Label(
                                                bookmarkedNews.contains(where: { $0.canonicalID == item.canonicalID }) ? "Remove Bookmark" : "Bookmark",
                                                systemImage: bookmarkedNews.contains(where: { $0.canonicalID == item.canonicalID }) ? "bookmark.fill" : "bookmark"
                                            )
                                        }
                                        
                                        Button {
                                            createTaskFromArticle(item)
                                        } label: {
                                            Label("Create Task", systemImage: "checklist")
                                        }
                                        
                                        Divider()
                                        
                                        Button {
                                            if let url = item.url {
                                                shareArticle(url: url, title: item.title)
                                            }
                                        } label: {
                                            Label("Share", systemImage: "square.and.arrow.up")
                                        }
                                        
                                        Button {
                                            UIPasteboard.general.string = item.url?.absoluteString ?? item.title
                                            HapticsManager.shared.light()
                                        } label: {
                                            Label("Copy Link", systemImage: "doc.on.doc")
                                        }
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
            .onChange(of: searchQuery) { _, newValue in
                // ✅ Task 25: Implement search debouncing
                searchTask?.cancel()
                
                guard !newValue.isEmpty else {
                    searchResults = []
                    isSearching = false
                    return
                }
                
                searchTask = Task {
                    isSearching = true
                    try? await Task.sleep(nanoseconds: 500_000_000) // 500ms debounce
                    
                    guard !Task.isCancelled else {
                        isSearching = false
                        return
                    }
                    
                    await performSearch(query: newValue)
                    isSearching = false
                }
            }
            .fullScreenCover(item: $selectedArticleURL) { identifiableURL in
                SafariView(url: identifiableURL.url)
                    .ignoresSafeArea()
            }
            .onDisappear {
                // ✅ Task 24: Cancel parsing on view disappear
                newsService.cancelParsing()
                searchTask?.cancel()
            }
        }
    }
    
    private func refreshNews() async {
        await newsService.fetchTopHeadlines(category: selectedCategory.lowercased())
        if !newsService.articles.isEmpty {
            news = newsService.articles.map { article in
                // ✅ P0 Fix: Use URL as canonical ID (Requirement 16.2)
                let canonicalID = article.url.isEmpty ? nil : article.url
                
                return NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "",
                    category: selectedCategory,
                    image: "newspaper.fill",
                    imageURL: article.urlToImage,
                    date: Date(),
                    url: URL(string: article.url),
                    dataSource: newsService.currentDataSource,
                    canonicalID: canonicalID
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
                // ✅ P0 Fix: Use URL as canonical ID (Requirement 16.2)
                let canonicalID = article.url.isEmpty ? nil : article.url
                
                return NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "No description available",
                    category: "RSS",
                    image: "antenna.radiowaves.left.and.right",
                    imageURL: article.urlToImage,
                    date: Date(),
                    url: URL(string: article.url),
                    dataSource: newsService.currentDataSource,
                    canonicalID: canonicalID
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
        // ✅ P1 Fix: Use canonical ID for deduplication
        let operationKey = item.canonicalID ?? item.id.uuidString
        guard !bookmarkOperations.contains(where: { $0.uuidString == operationKey || item.canonicalID == operationKey }) else {
            Logger.log("Bookmark operation already in progress", category: Logger.general)
            return
        }
        
        bookmarkOperations.insert(item.id)
        
        // ✅ P0 Fix: Use canonical ID for bookmark matching (Requirement 16.3)
        Task {
            defer {
                bookmarkOperations.remove(item.id)
            }
            
            do {
                if let existingBookmark = bookmarkedNews.first(where: { $0.canonicalID == item.canonicalID }) {
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
        // ✅ P1 Fix: Use canonical ID for deduplication
        let operationKey = item.canonicalID ?? item.id.uuidString
        guard !taskOperations.contains(where: { $0.uuidString == operationKey || item.canonicalID == operationKey }) else {
            Logger.log("Task creation already in progress", category: Logger.general)
            return
        }
        
        taskOperations.insert(item.id)
        
        // ✅ P1 Fix: Use database predicate instead of fetching all tasks
        Task {
            defer {
                taskOperations.remove(item.id)
            }
            
            do {
                let taskTitle = "Read: \(item.title)"
                
                // Use predicate to check existence without loading all tasks
                let predicate = #Predicate<TodoItem> { task in
                    task.title == taskTitle
                }
                var descriptor = FetchDescriptor<TodoItem>(predicate: predicate)
                descriptor.fetchLimit = 1
                
                let existingTasks = try modelContext.fetch(descriptor)
                
                if !existingTasks.isEmpty {
                    Logger.log("Task already exists for article", category: Logger.general)
                    return
                }
                
                // ✅ P2 Fix: Attach source URL to task notes
                let taskNotes = """
                Source: \(item.source)
                URL: \(item.url?.absoluteString ?? "N/A")
                
                \(item.summary)
                """
                
                let task = TodoItem(
                    title: taskTitle,
                    category: "Reading",
                    priority: 1,
                    notes: taskNotes
                )
                
                try await appDependency?.repositories.todo.save(task)
                HapticsManager.shared.success()
                Logger.log("Task created from article", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "NewsFeedView.createTaskFromArticle")
            }
        }
    }
    
    // ✅ Task 25: Perform API search
    private func performSearch(query: String) async {
        do {
            let articles = try await newsService.searchNews(query: query)
            
            searchResults = articles.map { article in
                let canonicalID = article.url.isEmpty ? nil : article.url
                
                return NewsItem(
                    source: article.source.name,
                    title: article.title,
                    summary: article.description ?? "",
                    category: "Search",
                    image: "magnifyingglass",
                    imageURL: article.urlToImage,
                    date: Date(),
                    url: URL(string: article.url),
                    dataSource: .real,
                    canonicalID: canonicalID
                )
            }
            
            Logger.log("Search completed: \(searchResults.count) results", category: Logger.general)
        } catch {
            // ✅ P1 Fix: Show error and fallback to local search
            Logger.error("Search API failed, using local search: \(error)", category: Logger.general)
            
            await MainActor.run {
                // Fallback to local filtering
                searchResults = news.filter { item in
                    item.title.localizedCaseInsensitiveContains(query) ||
                    item.summary.localizedCaseInsensitiveContains(query)
                }
                
                // Show error banner if API failed
                if searchResults.isEmpty {
                    newsService.error = "Search API unavailable. Showing local results."
                }
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
