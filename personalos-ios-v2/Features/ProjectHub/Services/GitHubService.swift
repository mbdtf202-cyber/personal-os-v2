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
class GitHubService {
    var repos: [GitHubRepo] = []
    var isLoading = false
    var error: String?
    var syncSuccess = false
    
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
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                error = "Failed to fetch repos"
                isLoading = false
                return
            }
            
            let decoder = JSONDecoder()
            repos = try decoder.decode([GitHubRepo].self, from: data)
            syncSuccess = true
            isLoading = false
            Logger.log("Successfully fetched \(repos.count) repositories from GitHub", category: Logger.general)
        } catch {
            self.error = error.localizedDescription
            isLoading = false
            Logger.error("GitHub sync failed: \(error.localizedDescription)", category: Logger.general)
        }
    }
}
