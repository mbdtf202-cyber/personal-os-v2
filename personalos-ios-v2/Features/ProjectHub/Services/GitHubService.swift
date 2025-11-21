import Foundation
import Combine

struct GitHubRepo: Codable, Identifiable {
    let id: Int
    let name: String
    let description: String?
    let language: String?
    let stargazersCount: Int
    let forksCount: Int
    let htmlUrl: String
    let updatedAt: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, description, language
        case stargazersCount = "stargazers_count"
        case forksCount = "forks_count"
        case htmlUrl = "html_url"
        case updatedAt = "updated_at"
    }
}

import Observation

@MainActor
@Observable
class GitHubService: GitHubServiceProtocol {
    var repos: [GitHubRepo] = []
    var isLoading = false
    var error: String?
    var syncSuccess = false
    
    private let networkClient: NetworkClient
    
    // 🔧 P1 Fix: 使用专用的 github 配置单例
    init(networkClient: NetworkClient = NetworkClient.github) {
        self.networkClient = networkClient
    }
    
    func fetchUserRepos(username: String) async {
        isLoading = true
        error = nil
        syncSuccess = false
        
        guard let url = URL(string: "https://api.github.com/users/\(username)/repos?sort=updated&per_page=50") else {
            error = "Invalid URL"
            isLoading = false
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        do {
            repos = try await networkClient.request(url: url)
            syncSuccess = true
            isLoading = false
            Logger.log("Successfully fetched \(repos.count) repositories from GitHub", category: Logger.general)
        } catch {
            self.error = error.localizedDescription
            ErrorHandler.shared.handle(error, context: "GitHubService.fetchUserRepos")
            isLoading = false
        }
    }
}

// MARK: - Protocol Conformance
struct GitHubRepository: Codable {
    let id: Int
    let name: String
    let description: String?
    let url: String
}

struct GitHubIssue: Codable {
    let id: Int
    let title: String
    let state: String
    let url: String
}

extension GitHubService {
    func fetchRepositories() async throws -> [GitHubRepository] {
        // Use existing repos or fetch
        if repos.isEmpty {
            await fetchUserRepos(username: "default")
        }
        
        return repos.map { repo in
            GitHubRepository(
                id: repo.id,
                name: repo.name,
                description: repo.description,
                url: repo.htmlUrl
            )
        }
    }
    
    func fetchIssues(repo: String) async throws -> [GitHubIssue] {
        guard let url = URL(string: "https://api.github.com/repos/\(repo)/issues") else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        
        return try await networkClient.request(url: url)
    }
}
