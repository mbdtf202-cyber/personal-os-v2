import SwiftUI
import SwiftData

struct NewsFeedView: View {
    @Environment(NewsService.self) private var newsService
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \NewsItem.date, order: .reverse) private var bookmarkedNews: [NewsItem]
    
    @State private var selectedCategory = "All"
    @State private var news: [NewsItem] = []
    @State private var selectedArticleURL: IdentifiableURL?
    @State private var readArticleIDs: Set<UUID> = []
    @State private var showRSSFeeds = false
    @State private var showBookmarks = false
    @State private var showSearch = false
    @State private var searchQuery = ""
    @State private var viewMode: ViewMode = .compact
    
    enum ViewMode {
        case compact, comfortable, magazine
    }
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Search Bar (when active)
                    if showSearch {
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
                    
                    // Category Filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(categories, id: \.self) { cat in
                                CategoryChip(
                                    title: cat,
                                    isSelected: selectedCategory == cat,
                                    action: { 
                                        selectedCategory = cat
                                        HapticsManager.shared.light()
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                    }
                    .background(AppTheme.background)
                    
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
                            EmptyNewsState(
                                hasAPIKey: APIConfig.hasValidNewsAPIKey,
                                searchQuery: searchQuery,
                                onRetry: refreshNews
                            )
                        } else {
                            LazyVStack(spacing: viewMode == .compact ? 12 : 16) {
                                // Error Banner
                                if let error = newsService.error {
                                    ErrorBanner(error: error, onRetry: refreshNews)
                                }
                                
                                ForEach(filteredNews) { item in
                                    Group {
                                        switch viewMode {
                                        case .compact:
                                            CompactNewsCard(
                                                item: item,
                                                isRead: readArticleIDs.contains(item.id),
                                                isBookmarked: bookmarkedNews.contains(where: { $0.id == item.id })
                                            )
                                        case .comfortable:
                                            ComfortableNewsCard(
                                                item: item,
                                                isRead: readArticleIDs.contains(item.id),
                                                isBookmarked: bookmarkedNews.contains(where: { $0.id == item.id })
                                            )
                                        case .magazine:
                                            MagazineNewsCard(
                                                item: item,
                                                isRead: readArticleIDs.contains(item.id),
                                                isBookmarked: bookmarkedNews.contains(where: { $0.id == item.id })
                                            )
                                        }
                                    }
                                    .onTapGesture {
                                        openArticle(item)
                                    }
                                    .contextMenu {
                                        newsContextMenu(for: item)
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
            .navigationTitle("News")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Menu {
                        Section("View Mode") {
                            Button(action: { viewMode = .compact }) {
                                Label("Compact", systemImage: viewMode == .compact ? "checkmark" : "")
                            }
                            Button(action: { viewMode = .comfortable }) {
                                Label("Comfortable", systemImage: viewMode == .comfortable ? "checkmark" : "")
                            }
                            Button(action: { viewMode = .magazine }) {
                                Label("Magazine", systemImage: viewMode == .magazine ? "checkmark" : "")
                            }
                        }
                        
                        Divider()
                        
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
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
            }
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
                Task {
                    if APIConfig.hasValidNewsAPIKey {
                        await refreshNews()
                    }
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
                    try await RepositoryContainer.shared.newsRepository.delete(existingBookmark)
                    HapticsManager.shared.light()
                    Logger.log("Bookmark removed: \(item.title)", category: Logger.general)
                } else {
                    // Add bookmark
                    try await RepositoryContainer.shared.newsRepository.save(item)
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
                try await RepositoryContainer.shared.todoRepository.save(task)
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
    
    @ViewBuilder
    private func newsContextMenu(for item: NewsItem) -> some View {
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
                Label(
                    bookmarkedNews.contains(where: { $0.id == item.id }) ? "Remove Bookmark" : "Bookmark",
                    systemImage: bookmarkedNews.contains(where: { $0.id == item.id }) ? "bookmark.fill" : "bookmark"
                )
            }
            
            Button(action: {
                createTaskFromArticle(item)
            }) {
                Label("Create Task", systemImage: "checkmark.circle")
            }
        }
    }
}

// MARK: - Category Chip
struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.mistBlue : Color.white)
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .clipShape(Capsule())
                .shadow(color: AppTheme.shadow.opacity(isSelected ? 0.3 : 0.1), radius: isSelected ? 6 : 3, y: 2)
        }
    }
}

// MARK: - Compact News Card
struct CompactNewsCard: View {
    let item: NewsItem
    var isRead: Bool
    var isBookmarked: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                CachedAsyncImage(url: imageURL, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 80, height: 80)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }, placeholder: {
                    thumbnailPlaceholder
                })
            } else {
                thumbnailPlaceholder
            }
            
            // Content
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    Text(item.source)
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.mistBlue)
                    
                    Text("•")
                        .foregroundStyle(AppTheme.tertiaryText)
                    
                    Text(item.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                    
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption2)
                            .foregroundStyle(AppTheme.almond)
                    }
                }
                
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(isRead ? AppTheme.secondaryText : AppTheme.primaryText)
                    .lineLimit(2)
                
                Text(item.summary)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: AppTheme.shadow.opacity(0.08), radius: 4, y: 2)
        .opacity(isRead ? 0.7 : 1.0)
    }
    
    private var thumbnailPlaceholder: some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: item.image)
                .font(.title3)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(width: 80, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Comfortable News Card
struct ComfortableNewsCard: View {
    let item: NewsItem
    var isRead: Bool
    var isBookmarked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack(spacing: 8) {
                Image(systemName: item.image)
                    .font(.caption)
                    .foregroundStyle(AppTheme.mistBlue)
                    .frame(width: 28, height: 28)
                    .background(AppTheme.mistBlue.opacity(0.1))
                    .clipShape(Circle())
                
                Text(item.source)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.secondaryText)
                
                Spacer()
                
                if isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.almond)
                }
                
                Text(item.date.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            // Title
            Text(item.title)
                .font(.headline)
                .foregroundStyle(isRead ? AppTheme.secondaryText : AppTheme.primaryText)
                .lineLimit(3)
            
            // Summary
            Text(item.summary)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
                .lineLimit(2)
            
            // Thumbnail (if available)
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                CachedAsyncImage(url: imageURL, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }, placeholder: {
                    imagePlaceholder(height: 120)
                })
            }
            
            // Footer
            HStack {
                Label(item.category, systemImage: "tag.fill")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.almond)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: AppTheme.shadow.opacity(0.1), radius: 6, y: 3)
        .opacity(isRead ? 0.7 : 1.0)
    }
    
    private func imagePlaceholder(height: CGFloat) -> some View {
        ZStack {
            Color.gray.opacity(0.15)
            Image(systemName: "photo")
                .font(.title2)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Magazine News Card
struct MagazineNewsCard: View {
    let item: NewsItem
    var isRead: Bool
    var isBookmarked: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Large Image
            if let imageURLString = item.imageURL, let imageURL = URL(string: imageURLString) {
                CachedAsyncImage(url: imageURL, content: { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 200)
                        .clipped()
                }, placeholder: {
                    magazinePlaceholder
                })
            } else {
                magazinePlaceholder
            }
            
            // Content
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(item.source, systemImage: item.image)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.mistBlue)
                    
                    Spacer()
                    
                    if isBookmarked {
                        Image(systemName: "bookmark.fill")
                            .font(.caption)
                            .foregroundStyle(AppTheme.almond)
                    }
                    
                    Text(item.date.formatted(.relative(presentation: .named)))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.tertiaryText)
                }
                
                Text(item.title)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(isRead ? AppTheme.secondaryText : AppTheme.primaryText)
                    .lineLimit(3)
                
                Text(item.summary)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(3)
                
                HStack {
                    Label(item.category, systemImage: "tag.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.almond)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppTheme.almond.opacity(0.1))
                        .clipShape(Capsule())
                    
                    Spacer()
                    
                    Image(systemName: "arrow.up.right.circle.fill")
                        .font(.title3)
                        .foregroundStyle(AppTheme.mistBlue)
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow.opacity(0.12), radius: 8, y: 4)
        .opacity(isRead ? 0.7 : 1.0)
    }
    
    private var magazinePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: [AppTheme.mistBlue.opacity(0.3), AppTheme.lavender.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: item.image)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(height: 200)
    }
}

// MARK: - Error Banner
struct ErrorBanner: View {
    let error: String
    let onRetry: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(AppTheme.coral)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Failed to load news")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Spacer()
            
            Button {
                Task { await onRetry() }
            } label: {
                Text("Retry")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.mistBlue)
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(AppTheme.coral.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Empty State
struct EmptyNewsState: View {
    let hasAPIKey: Bool
    let searchQuery: String
    let onRetry: () async -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: searchQuery.isEmpty ? "newspaper" : "magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(AppTheme.tertiaryText)
            
            VStack(spacing: 8) {
                Text(searchQuery.isEmpty ? "No News Available" : "No Results Found")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
                
                if searchQuery.isEmpty {
                    Text(hasAPIKey ? "Pull to refresh or try again" : "Configure News API key in Settings")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Try a different search term")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            if searchQuery.isEmpty && hasAPIKey {
                Button {
                    Task { await onRetry() }
                } label: {
                    Text("Retry")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(AppTheme.mistBlue)
                        .clipShape(Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
        .padding(.horizontal, 40)
    }
}

#Preview {
    NewsFeedView()
        .modelContainer(for: NewsItem.self, inMemory: true)
}
