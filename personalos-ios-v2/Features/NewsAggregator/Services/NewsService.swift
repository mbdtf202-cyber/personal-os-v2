import Foundation
import Combine

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
    
    private var apiKey: String {
        APIConfig.newsAPIKey
    }
    
    func fetchTopHeadlines(category: String = "technology") async {
        isLoading = true
        error = nil
        
        // Use mock data if API key not configured
        guard APIConfig.hasValidNewsAPIKey else {
            Logger.debug("News API key not configured, skipping fetch", category: Logger.network)
            isLoading = false
            return
        }
        
        guard let url = URL(string: "https://newsapi.org/v2/top-headlines?category=\(category)&language=en&apiKey=\(apiKey)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Failed to fetch news"
                Logger.error("News API request failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)", category: Logger.network)
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            let newsResponse = try decoder.decode(NewsResponse.self, from: data)
            articles = newsResponse.articles
            Logger.log("Successfully fetched \(articles.count) news articles", category: Logger.network)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to fetch news: \(error.localizedDescription)", category: Logger.network)
            isLoading = false
        }
    }
    
    func fetchFromRSS(feedURL: String) async {
        isLoading = true
        error = nil
        
        guard let url = URL(string: feedURL) else {
            error = "Invalid RSS URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Failed to fetch RSS feed"
                Logger.error("RSS fetch failed with status: \((response as? HTTPURLResponse)?.statusCode ?? 0)", category: Logger.network)
                isLoading = false
                return
            }
            
            let parser = RSSParser()
            let parsedArticles = parser.parse(data: data)
            
            // Convert to NewsArticle format
            articles = parsedArticles.map { article in
                NewsArticle(
                    title: article.title,
                    description: article.description,
                    url: article.link,
                    urlToImage: nil,
                    publishedAt: article.pubDate,
                    source: NewsArticle.NewsSource(name: "RSS Feed")
                )
            }
            
            Logger.log("Successfully fetched \(articles.count) articles from RSS", category: Logger.network)
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            Logger.error("Failed to fetch RSS: \(error.localizedDescription)", category: Logger.network)
            isLoading = false
        }
    }
    
    func fetchFromMultipleRSSFeeds(feeds: [RSSFeed]) async {
        isLoading = true
        error = nil
        var allArticles: [NewsArticle] = []
        
        for feed in feeds where feed.isEnabled {
            guard let url = URL(string: feed.url) else { continue }
            
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                let parser = RSSParser()
                let parsedArticles = parser.parse(data: data)
                
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
        Logger.log("Successfully fetched \(articles.count) articles from \(feeds.count) RSS feeds", category: Logger.network)
        isLoading = false
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
        
        guard let url = URL(string: "https://newsapi.org/v2/everything?q=\(query)&language=en&apiKey=\(apiKey)") else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let newsResponse = try JSONDecoder().decode(NewsResponse.self, from: data)
        return newsResponse.articles
    }
}
