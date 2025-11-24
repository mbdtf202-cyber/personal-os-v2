import SwiftUI
import SwiftData

@Observable
@MainActor
class SocialDashboardViewModel: BaseViewModel {
    var showEditor = false
    var newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
    var selectedPost: SocialPost?
    var selectedDate: Date?
    
    // ✅ P0 Fix: Operation feedback state
    private(set) var lastOperation: OperationResult?
    private(set) var isLoading: Bool = false
    
    // ✅ P0 Fix: Task lifecycle management
    private var ongoingTasks: [Task<Void, Never>] = []
    
    private let socialPostRepository: SocialPostRepository
    
    init(socialPostRepository: SocialPostRepository) {
        self.socialPostRepository = socialPostRepository
    }
    
    // ✅ P0 Fix: Cancel ongoing tasks on view disappear
    func cancelOngoingTasks() {
        for task in ongoingTasks {
            task.cancel()
        }
        ongoingTasks.removeAll()
    }
    
    deinit {
        cancelOngoingTasks()
    }
    
    // ✅ P0 Fix: Enhanced savePost with feedback
    func savePost(_ post: SocialPost) async {
        isLoading = true
        lastOperation = nil
        
        do {
            try Task.checkCancellation()
            try await socialPostRepository.save(post)
            try Task.checkCancellation()
            
            Logger.log("Post saved: \(post.title)", category: Logger.general)
            
            // Success feedback
            lastOperation = OperationResult(
                type: .save,
                success: true,
                message: "Post saved successfully"
            )
            
            // Clear feedback after delay
            let clearTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    lastOperation = nil
                }
            }
            ongoingTasks.append(clearTask)
            
        } catch is CancellationError {
            // Task was cancelled, don't update state
            Logger.log("Save post task cancelled", category: Logger.general)
        } catch {
            Logger.error("Failed to save post: \(error)", category: Logger.general)
            
            // Failure feedback
            lastOperation = OperationResult(
                type: .save,
                success: false,
                message: "Failed to save post: \(error.localizedDescription)"
            )
            
            ErrorHandler.shared.handle(error, context: "SocialDashboardViewModel.savePost")
        }
        
        isLoading = false
    }
    
    // ✅ P0 Fix: Enhanced deletePost with feedback
    func deletePost(_ post: SocialPost) async {
        isLoading = true
        lastOperation = nil
        
        do {
            try Task.checkCancellation()
            try await socialPostRepository.delete(post)
            try Task.checkCancellation()
            
            Logger.log("Post deleted", category: Logger.general)
            
            // Success feedback
            lastOperation = OperationResult(
                type: .delete,
                success: true,
                message: "Post deleted successfully"
            )
            
            // Clear feedback after delay
            let clearTask = Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                if !Task.isCancelled {
                    lastOperation = nil
                }
            }
            ongoingTasks.append(clearTask)
            
        } catch is CancellationError {
            // Task was cancelled, don't update state
            Logger.log("Delete post task cancelled", category: Logger.general)
        } catch {
            Logger.error("Failed to delete post: \(error)", category: Logger.general)
            
            // Failure feedback
            lastOperation = OperationResult(
                type: .delete,
                success: false,
                message: "Failed to delete post: \(error.localizedDescription)"
            )
            
            ErrorHandler.shared.handle(error, context: "SocialDashboardViewModel.deletePost")
        }
        
        isLoading = false
    }
    
    func changePostStatus(_ post: SocialPost, to status: PostStatus) async {
        post.status = status
        await savePost(post)
        HapticsManager.shared.light()
    }
    
    func seedDefaultPosts() async {
        do {
            let existingPosts = try await socialPostRepository.fetch()
            guard existingPosts.isEmpty else { return }
            
            for post in SocialPost.defaultPosts {
                try await socialPostRepository.save(post)
            }
            Logger.log("Seeded default social posts", category: Logger.general)
        } catch {
            ErrorHandler.shared.handle(error, context: "SocialDashboardViewModel.seedDefaultPosts")
        }
    }
    
    func calculateStats(from posts: [SocialPost]) -> (totalViews: String, engagementRate: String) {
        let totalViews = posts.reduce(0) { $0 + $1.views }
        let totalLikes = posts.reduce(0) { $0 + $1.likes }
        
        let viewsString: String
        if totalViews >= 1000 {
            viewsString = String(format: "%.1fK", Double(totalViews) / 1000.0)
        } else {
            viewsString = "\(totalViews)"
        }
        
        let engagementString: String
        if totalViews > 0 {
            let rate = (Double(totalLikes) / Double(totalViews)) * 100
            engagementString = String(format: "%.1f%%", rate)
        } else {
            engagementString = "0%"
        }
        
        return (viewsString, engagementString)
    }
    
    func filterPosts(_ posts: [SocialPost], by status: PostStatus, date: Date? = nil) -> [SocialPost] {
        var filtered = posts.filter { $0.status == status }
        
        if let date = date {
            filtered = filtered.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
        }
        
        return filtered.sorted { $0.date < $1.date }
    }
}


/// Operation result for user feedback
struct OperationResult {
    let type: OperationType
    let success: Bool
    let message: String
    
    var icon: String {
        success ? "checkmark.circle.fill" : "xmark.circle.fill"
    }
    
    var color: Color {
        success ? .green : .red
    }
}

/// Operation type
enum OperationType {
    case save
    case delete
    case update
    
    var description: String {
        switch self {
        case .save: return "Save"
        case .delete: return "Delete"
        case .update: return "Update"
        }
    }
}
