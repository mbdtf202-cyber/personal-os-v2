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
    
    init(networkClient: NetworkClient) {
        self.networkClient = networkClient
    }
    
    func fetchUserRepos(username: String) async {
        isLoading = true
        error = nil
        syncSuccess = false
        
        let endpoint = GitHubEndpoint.userRepos(username: username, perPage: 50)
        
        do {
            repos = try await networkClient.request(endpoint)
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
        let components = repo.split(separator: "/")
        guard components.count == 2 else {
            throw URLError(.badURL)
        }
        
        let endpoint = GitHubEndpoint.repoIssues(
            owner: String(components[0]),
            repo: String(components[1])
        )
        
        return try await networkClient.request(endpoint)
    }
}
