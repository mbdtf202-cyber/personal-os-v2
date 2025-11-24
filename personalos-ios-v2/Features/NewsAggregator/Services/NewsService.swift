import Foundation
import Combine

protocol NewsServiceProtocol {
    func fetchNews(category: String?) async throws -> [NewsArticle]
    func searchNews(query: String) async throws -> [NewsArticle]
}

struct NewsArticle: Codable, Identifiable {
    let id = UUID()
    let title: String
    let description: String?
    let url: String
    let urlToImage: String?
    let publishedAt: String
    let source: NewsSource
    
    struct NewsSource: Codable {
        let name: String
    }
    
    enum CodingKeys: String, CodingKey {
        case title, description, url, urlToImage, publishedAt, source
    }
}

struct NewsResponse: Codable {
    let articles: [NewsArticle]
}

import Observation

@MainActor
@Observable
class NewsService: NewsServiceProtocol {
    var articles: [NewsArticle] = []
    var isLoading = false
    var error: String?
    
    // ✅ P0 Fix: Data source tracking (Requirement 14.2)
    private(set) var currentDataSource: NewsDataSource = .demo
    
    // ✅ P0 Fix: API security infrastructure (Requirements 15.2-15.5)
    private let throttler: RequestThrottler
    private let retryStrategy: RetryStrategy
    private let circuitBreaker: CircuitBreaker
    
    // ✅ Task 23: Response caching with TTL
    private var responseCache: [String: CachedResponse] = [:]
    private let cacheTTL: TimeInterval = 300 // 5 minutes
    
    // ✅ Task 24: Background parsing state
    private(set) var isParsingNews = false
    private var parsingTask: Task<Void, Never>?
    
    private let networkClient: NetworkClient
    private var apiKey: String {
        APIConfig.newsAPIKey
    }
    
    init(networkClient: NetworkClient,
         throttler: RequestThrottler = RequestThrottler(maxRequestsPerMinute: 60),
         retryStrategy: RetryStrategy = RetryStrategy(),
         circuitBreaker: CircuitBreaker = CircuitBreaker()) {
        self.networkClient = networkClient
        self.throttler = throttler
        self.retryStrategy = retryStrategy
        self.circuitBreaker = circuitBreaker
    }
    
    /// Check if using real data or demo/mock data
    var isUsingRealData: Bool {
        currentDataSource == .real
    }
    
    func fetchTopHeadlines(category: String = "technology") async {
        isLoading = true
        error = nil
        
        guard APIConfig.hasValidNewsAPIKey else {
            Logger.debug("News API key not configured, skipping fetch", category: Logger.network)
            currentDataSource = .demo
            isLoading = false
            return
        }
        
        // ✅ Task 23: Check cache first
        let endpointKey = "news-headlines-\(category)"
        if let cached = responseCache[endpointKey], !cached.isExpired {
            articles = cached.articles
            currentDataSource = .real
            Logger.log("Using cached response for \(endpointKey)", category: Logger.network)
            isLoading = false
            return
        }
        
        // ✅ P0 Fix: Check throttling (Requirement 15.2)
        guard throttler.canMakeRequest(for: endpointKey) else {
            let waitTime = throttler.timeUntilNextRequest(for: endpointKey)
            self.error = "Rate limit reached. Please wait \(Int(waitTime))s"
            Logger.log("Request throttled for \(endpointKey)", category: Logger.network)
            isLoading = false
            return
        }
        
        let endpoint = NewsEndpoint.topHeadlines(category: category, apiKey: apiKey)
        
        do {
            // ✅ P0 Fix: Use circuit breaker and retry strategy (Requirements 15.3, 15.4)
            let newsResponse: NewsResponse = try await circuitBreaker.execute {
                try await retryStrategy.execute {
                    try await networkClient.request(endpoint)
                }
            }
            
            throttler.recordRequest(for: endpointKey)
            articles = newsResponse.articles
            currentDataSource = .real
            
            // ✅ Task 23: Cache the response
            responseCache[endpointKey] = CachedResponse(articles: newsResponse.articles, timestamp: Date())
            
            // ✅ P0 Fix: Log API usage (Requirement 15.5)
            Logger.log("API Request: \(endpointKey) - Success - \(articles.count) articles", category: Logger.network)
            
            isLoading = false
        } catch {
            // ✅ Task 23: Try to use offline cache if available
            if let cached = responseCache[endpointKey] {
                articles = cached.articles
                currentDataSource = .real
                self.error = "Using offline cache (last updated: \(formatTimestamp(cached.timestamp)))"
                Logger.log("Using offline cache for \(endpointKey)", category: Logger.network)
            } else {
                self.error = error.localizedDescription
                currentDataSource = .demo
                
                // ✅ P0 Fix: Log API failure (Requirement 15.5)
                Logger.error("API Request: \(endpointKey) - Failed - \(error.localizedDescription)", category: Logger.network)
                
                ErrorHandler.shared.handle(error, context: "NewsService.fetchTopHeadlines")
            }
            isLoading = false
        }
    }
    
    func fetchFromRSS(feedURL: String) async {
        isLoading = true
        isParsingNews = false
        error = nil
        
        guard let url = URL(string: feedURL) else {
            error = "Invalid RSS URL"
            currentDataSource = .demo
            isLoading = false
            return
        }
        
        do {
            let data = try await networkClient.requestData(url: url)
            
            // ✅ Task 24: Parse on background thread
            isParsingNews = true
            isLoading = false
            
            parsingTask = Task.detached {
                let parser = RSSParser()
                let parsedArticles = parser.parse(data: data)
                
                // ✅ Task 24: Update UI on main thread
                await MainActor.run {
                    self.articles = parsedArticles.map { article in
                        NewsArticle(
                            title: article.title,
                            description: article.description,
                            url: article.link,
                            urlToImage: nil,
                            publishedAt: article.pubDate,
                            source: NewsArticle.NewsSource(name: "RSS Feed")
                        )
                    }
                    
                    self.currentDataSource = .real
                    self.isParsingNews = false
                    Logger.log("Successfully fetched \(self.articles.count) articles from RSS", category: Logger.network)
                }
            }
            
            await parsingTask?.value
        } catch {
            self.error = error.localizedDescription
            currentDataSource = .demo
            isParsingNews = false
            ErrorHandler.shared.handle(error, context: "NewsService.fetchFromRSS")
            isLoading = false
        }
    }
    
    // ✅ Task 24: Cancel parsing
    func cancelParsing() {
        parsingTask?.cancel()
        parsingTask = nil
        isParsingNews = false
    }
    
    func fetchFromMultipleRSSFeeds(feeds: [RSSFeed]) async {
        isLoading = true
        error = nil
        var allArticles: [NewsArticle] = []
        
        for feed in feeds where feed.isEnabled {
            guard let url = URL(string: feed.url) else { continue }
            
            do {
                let data = try await networkClient.requestData(url: url)
                let parser = RSSParser()
                let parsedArticles = await parser.parse(data: data)
                
                let feedArticles = parsedArticles.map { article in
                    NewsArticle(
                        title: article.title,
                        description: article.description,
                        url: article.link,
                        urlToImage: nil,
                        publishedAt: article.pubDate,
                        source: NewsArticle.NewsSource(name: feed.name)
                    )
                }
                
                allArticles.append(contentsOf: feedArticles)
            } catch {
                Logger.error("Failed to fetch RSS from \(feed.name): \(error.localizedDescription)", category: Logger.network)
            }
        }
        
        articles = allArticles
        currentDataSource = allArticles.isEmpty ? .demo : .real // ✅ Set data source
        Logger.log("Successfully fetched \(articles.count) articles from \(feeds.count) RSS feeds", category: Logger.network)
        isLoading = false
    }
}

    // ✅ Task 23: Helper to format timestamp
    private func formatTimestamp(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Cached Response
/// ✅ Task 23: Response cache structure with TTL
private struct CachedResponse {
    let articles: [NewsArticle]
    let timestamp: Date
    
    var isExpired: Bool {
        Date().timeIntervalSince(timestamp) > 300 // 5 minutes TTL
    }
}

// MARK: - Protocol Conformance
extension NewsService {
    func fetchNews(category: String?) async throws -> [NewsArticle] {
        await fetchTopHeadlines(category: category ?? "technology")
        return articles
    }
    
    func searchNews(query: String) async throws -> [NewsArticle] {
        guard APIConfig.hasValidNewsAPIKey else {
            return []
        }
        
        // ✅ Task 25: Implement search with debouncing (handled in view)
        // ✅ P0 Fix: Apply security measures to search
        let endpointKey = "news-search-\(query)"
        guard throttler.canMakeRequest(for: endpointKey) else {
            throw AppError.rateLimitExceeded
        }
        
        let endpoint = NewsEndpoint.search(query: query, apiKey: apiKey)
        
        let newsResponse: NewsResponse = try await circuitBreaker.execute {
            try await retryStrategy.execute {
                try await networkClient.request(endpoint)
            }
        }
        
        throttler.recordRequest(for: endpointKey)
        Logger.log("API Request: \(endpointKey) - Success - \(newsResponse.articles.count) results", category: Logger.network)
        
        return newsResponse.articles
    }
}
