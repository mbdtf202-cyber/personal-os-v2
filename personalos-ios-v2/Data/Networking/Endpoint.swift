import Foundation

protocol Endpoint {
    var baseURL: String { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var headers: [String: String]? { get }
    var queryItems: [URLQueryItem]? { get }
    var body: Data? { get }
    
    func makeURL() -> URL?
}

extension Endpoint {
    var headers: [String: String]? { nil }
    var queryItems: [URLQueryItem]? { nil }
    var body: Data? { nil }
    
    func makeURL() -> URL? {
        guard var components = URLComponents(string: baseURL + path) else {
            return nil
        }
        components.queryItems = queryItems
        return components.url
    }
}

// MARK: - GitHub Endpoints
enum GitHubEndpoint: Endpoint {
    case userRepos(username: String, perPage: Int, page: Int, token: String?)
    case repoIssues(owner: String, repo: String)
    
    var baseURL: String { "https://api.github.com" }
    
    var path: String {
        switch self {
        case .userRepos(let username, _, _, _):
            return "/users/\(username)/repos"
        case .repoIssues(let owner, let repo):
            return "/repos/\(owner)/\(repo)/issues"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var headers: [String: String]? {
        var headers = ["Accept": "application/vnd.github.v3+json"]
        
        switch self {
        case .userRepos(_, _, _, let token):
            if let token = token {
                headers["Authorization"] = "Bearer \(token)"
            }
        case .repoIssues:
            break
        }
        
        return headers
    }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .userRepos(_, let perPage, let page, _):
            return [
                URLQueryItem(name: "sort", value: "updated"),
                URLQueryItem(name: "per_page", value: "\(perPage)"),
                URLQueryItem(name: "page", value: "\(page)")
            ]
        case .repoIssues:
            return nil
        }
    }
}

// MARK: - News Endpoints
enum NewsEndpoint: Endpoint {
    case topHeadlines(category: String, apiKey: String)
    case search(query: String, apiKey: String)
    
    var baseURL: String { "https://newsapi.org/v2" }
    
    var path: String {
        switch self {
        case .topHeadlines:
            return "/top-headlines"
        case .search:
            return "/everything"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .topHeadlines(let category, let apiKey):
            return [
                URLQueryItem(name: "category", value: category),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "apiKey", value: apiKey)
            ]
        case .search(let query, let apiKey):
            return [
                URLQueryItem(name: "q", value: query),
                URLQueryItem(name: "language", value: "en"),
                URLQueryItem(name: "apiKey", value: apiKey)
            ]
        }
    }
}

// MARK: - Stock Endpoints
enum StockEndpoint: Endpoint {
    case quote(symbol: String, apiKey: String)
    
    var baseURL: String { "https://api.example.com" }
    
    var path: String {
        switch self {
        case .quote(let symbol, _):
            return "/quote/\(symbol)"
        }
    }
    
    var method: HTTPMethod { .get }
    
    var queryItems: [URLQueryItem]? {
        switch self {
        case .quote(_, let apiKey):
            return [URLQueryItem(name: "apikey", value: apiKey)]
        }
    }
}

// MARK: - NetworkClient Extension
extension NetworkClient {
    @MainActor
    func request<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        guard let url = endpoint.makeURL() else {
            throw NetworkError.invalidURL
        }
        
        return try await request(
            url.absoluteString,
            method: endpoint.method,
            headers: endpoint.headers,
            body: endpoint.body
        )
    }
}
