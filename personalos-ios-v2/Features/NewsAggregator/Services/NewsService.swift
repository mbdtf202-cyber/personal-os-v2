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

@MainActor
class NewsService: ObservableObject {
    @Published var articles: [NewsArticle] = []
    @Published var isLoading = false
    @Published var error: String?
    
    // Use NewsAPI.org - Get free API key at https://newsapi.org
    private let apiKey = "YOUR_API_KEY_HERE" // TODO: Replace with real key
    
    func fetchTopHeadlines(category: String = "technology") async {
        isLoading = true
        error = nil
        
        guard let url = URL(string: "https://newsapi.org/v2/top-headlines?category=\(category)&language=en&apiKey=\(apiKey)") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Failed to fetch news"
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            let newsResponse = try decoder.decode(NewsResponse.self, from: data)
            articles = newsResponse.articles
            isLoading = false
        } catch {
            self.error = error.localizedDescription
            isLoading = false
        }
    }
    
    func fetchFromRSS(feedURL: String) async {
        // TODO: Implement RSS parser
        isLoading = true
        // Placeholder for RSS parsing logic
        isLoading = false
    }
}
