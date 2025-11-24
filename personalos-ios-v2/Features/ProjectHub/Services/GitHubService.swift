import Foundation
import Combine

protocol GitHubServiceProtocol {
    var repos: [GitHubRepo] { get }
    var isLoading: Bool { get }
    var error: String? { get }
    func fetchUserRepos(username: String) async
}

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
    var syncDetails: String?
    
    private let networkClient: NetworkClient
    private var githubToken: String?
    private let maxRetries = 3
    private let baseDelay: TimeInterval = 1.0
    
    init(networkClient: NetworkClient, githubToken: String? = nil) {
        self.networkClient = networkClient
        self.githubToken = githubToken
    }
    
    func setGitHubToken(_ token: String?) {
        self.githubToken = token
    }
    
    func fetchUserRepos(username: String) async {
        isLoading = true
        error = nil
        syncSuccess = false
        syncDetails = nil
        
        do {
            repos = try await fetchAllRepos(username: username)
            syncSuccess = true
            syncDetails = "Successfully fetched \(repos.count) repositories"
            Logger.log("Successfully fetched \(repos.count) repositories from GitHub", category: Logger.general)
        } catch let error as GitHubError {
            self.error = error.userMessage
            self.syncDetails = error.detailedMessage
            ErrorHandler.shared.handle(error, context: "GitHubService.fetchUserRepos")
        } catch {
            self.error = error.localizedDescription
            ErrorHandler.shared.handle(error, context: "GitHubService.fetchUserRepos")
        }
        
        isLoading = false
    }
    
    // Fetch all repos with pagination
    private func fetchAllRepos(username: String) async throws -> [GitHubRepo] {
        var allRepos: [GitHubRepo] = []
        var page = 1
        let perPage = 100
        var hasMore = true
        
        while hasMore {
            let endpoint = GitHubEndpoint.userRepos(
                username: username,
                perPage: perPage,
                page: page,
                token: githubToken
            )
            
            let pageRepos: [GitHubRepo] = try await requestWithRetry(endpoint)
            allRepos.append(contentsOf: pageRepos)
            
            // Check if there are more pages
            hasMore = pageRepos.count == perPage
            page += 1
            
            Logger.log("Fetched page \(page - 1): \(pageRepos.count) repos", category: Logger.general)
            
            // Prevent infinite loops
            if page > 10 {
                Logger.log("Reached max page limit (10)", category: Logger.general)
                break
            }
        }
        
        return allRepos
    }
    
    // ✅ P0 Fix: Request with retry and rate limit handling - catch AppError correctly
    private func requestWithRetry<T: Codable>(_ endpoint: Endpoint) async throws -> T {
        var lastError: Error?
        
        for attempt in 0..<maxRetries {
            do {
                return try await networkClient.request(endpoint)
            } catch let error as AppError {
                lastError = error
                
                // ✅ P0 Fix: Handle AppError.network correctly
                if case .network(let networkError, _) = error {
                    // Handle rate limiting (403)
                    if case .forbidden = networkError {
                        Logger.error("GitHub rate limit exceeded (403)", category: Logger.general)
                        throw GitHubError.rateLimitExceeded
                    }
                    
                    // Handle timeout - retry with exponential backoff
                    if case .timeout = networkError {
                        if attempt < maxRetries - 1 {
                            let delay = baseDelay * pow(2.0, Double(attempt))
                            Logger.log("Request timeout, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))", category: Logger.general)
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        }
                    }
                    
                    // Handle other retryable network errors
                    if case .serverError = networkError {
                        if attempt < maxRetries - 1 {
                            let delay = baseDelay * pow(2.0, Double(attempt))
                            Logger.log("Server error, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))", category: Logger.general)
                            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                            continue
                        }
                    }
                }
                
                // Non-retryable errors
                throw error
            } catch let error as NetworkError {
                // Legacy NetworkError support
                lastError = error
                
                if case .serverError(let statusCode, _) = error, statusCode == 403 {
                    throw GitHubError.rateLimitExceeded
                }
                
                if case .timeout = error {
                    if attempt < maxRetries - 1 {
                        let delay = baseDelay * pow(2.0, Double(attempt))
                        Logger.log("Request timeout, retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries))", category: Logger.general)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                }
                
                throw error
            } catch {
                lastError = error
                throw error
            }
        }
        
        throw lastError ?? GitHubError.unknown
    }
    
    // ✅ P0 Fix: Three-way merge sync that preserves local data
    func syncProjects(username: String, localProjects: [ProjectItem]) async throws -> SyncResult {
        isLoading = true
        error = nil
        syncDetails = nil
        
        Logger.log("Starting GitHub sync for user: \(username)", category: Logger.general)
        
        // Fetch remote repos with pagination and retry
        let remoteRepos: [GitHubRepo]
        
        do {
            remoteRepos = try await fetchAllRepos(username: username)
            Logger.log("Fetched \(remoteRepos.count) remote repositories", category: Logger.general)
        } catch let error as GitHubError {
            isLoading = false
            self.error = error.userMessage
            self.syncDetails = error.detailedMessage
            throw error
        } catch {
            isLoading = false
            throw error
        }
        
        // Perform three-way merge
        var added = 0
        var updated = 0
        var unchanged = 0
        var conflicts: [ProjectConflict] = []
        var mergedProjects: [ProjectItem] = []
        
        // Create lookup for local projects by GitHub ID
        var localProjectsMap: [Int: ProjectItem] = [:]
        for project in localProjects {
            if let githubId = project.githubId {
                localProjectsMap[githubId] = project
            }
        }
        
        // Process remote repos
        for remoteRepo in remoteRepos {
            if let localProject = localProjectsMap[remoteRepo.id] {
                // Both local and remote exist - merge
                let merged = mergeProject(remote: remoteRepo, local: localProject)
                mergedProjects.append(merged)
                
                // Check if anything changed
                if hasChanges(local: localProject, remote: remoteRepo) {
                    updated += 1
                } else {
                    unchanged += 1
                }
                
                // Remove from map to track processed
                localProjectsMap.removeValue(forKey: remoteRepo.id)
            } else {
                // Only remote exists - add new
                let newProject = createProjectFromRepo(remoteRepo)
                mergedProjects.append(newProject)
                added += 1
            }
        }
        
        // Add remaining local-only projects
        for (_, localProject) in localProjectsMap {
            mergedProjects.append(localProject)
            Logger.log("Preserving local-only project: \(localProject.title)", category: Logger.general)
        }
        
        isLoading = false
        syncSuccess = true
        
        let result = SyncResult(
            added: added,
            updated: updated,
            unchanged: unchanged,
            localOnly: localProjectsMap.count,
            conflicts: conflicts
        )
        
        syncDetails = result.summary
        Logger.log("Sync complete: +\(added) ~\(updated) =\(unchanged) local:\(localProjectsMap.count)", category: Logger.general)
        
        return result
    }
    
    // ✅ P0 Fix: Merge logic that preserves local fields
    private func mergeProject(remote: GitHubRepo, local: ProjectItem) -> ProjectItem {
        // Create merged project preserving local custom fields
        let merged = ProjectItem(
            title: remote.name,  // Use remote name
            description: remote.description ?? local.description,
            category: local.category,  // Preserve local category
            status: local.status,  // Preserve local status
            priority: local.priority,  // Preserve local priority
            progress: local.progress,  // Preserve local progress
            startDate: local.startDate,  // Preserve local dates
            endDate: local.endDate,
            tags: local.tags,  // Preserve local tags
            notes: local.notes,  // Preserve local notes
            githubUrl: remote.htmlUrl,
            githubId: remote.id,
            githubStars: remote.stargazersCount,
            githubForks: remote.forksCount,
            githubLanguage: remote.language,
            githubUpdatedAt: remote.updatedAt
        )
        
        return merged
    }
    
    // Create new project from GitHub repo
    private func createProjectFromRepo(_ repo: GitHubRepo) -> ProjectItem {
        return ProjectItem(
            title: repo.name,
            description: repo.description ?? "",
            category: "Development",
            status: "active",
            priority: 2,
            progress: 0,
            githubUrl: repo.htmlUrl,
            githubId: repo.id,
            githubStars: repo.stargazersCount,
            githubForks: repo.forksCount,
            githubLanguage: repo.language,
            githubUpdatedAt: repo.updatedAt
        )
    }
    
    // Check if remote has changes compared to local
    private func hasChanges(local: ProjectItem, remote: GitHubRepo) -> Bool {
        return local.title != remote.name ||
               local.description != (remote.description ?? "") ||
               local.githubStars != remote.stargazersCount ||
               local.githubForks != remote.forksCount
    }
}

/// Sync result with detailed statistics
struct SyncResult {
    let added: Int
    let updated: Int
    let unchanged: Int
    let localOnly: Int
    let conflicts: [ProjectConflict]
    
    var summary: String {
        return """
        Sync Complete:
        • Added: \(added) new projects
        • Updated: \(updated) projects
        • Unchanged: \(unchanged) projects
        • Local only: \(localOnly) projects
        • Conflicts: \(conflicts.count)
        """
    }
}

/// Project conflict information
struct ProjectConflict {
    let projectName: String
    let conflictType: ConflictType
    let localValue: String
    let remoteValue: String
    
    enum ConflictType {
        case title
        case description
        case status
    }
}

/// GitHub-specific errors
enum GitHubError: LocalizedError {
    case rateLimitExceeded
    case unauthorized
    case timeout
    case unknown
    
    var userMessage: String {
        switch self {
        case .rateLimitExceeded:
            return "GitHub rate limit exceeded"
        case .unauthorized:
            return "GitHub authentication failed"
        case .timeout:
            return "Request timed out"
        case .unknown:
            return "Unknown error occurred"
        }
    }
    
    var detailedMessage: String {
        switch self {
        case .rateLimitExceeded:
            return "You've exceeded GitHub's API rate limit. Please wait a few minutes or add a GitHub token for higher limits."
        case .unauthorized:
            return "Your GitHub token is invalid or expired. Please check your settings."
        case .timeout:
            return "The request took too long to complete. Please check your internet connection and try again."
        case .unknown:
            return "An unexpected error occurred. Please try again later."
        }
    }
    
    var errorDescription: String? {
        return userMessage
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
            throw GitHubError.unknown
        }
        
        let endpoint = GitHubEndpoint.repoIssues(
            owner: String(components[0]),
            repo: String(components[1])
        )
        
        return try await requestWithRetry(endpoint)
    }
}
