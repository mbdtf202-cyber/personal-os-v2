import SwiftUI
import SwiftData

@Observable
@MainActor
class SocialDashboardViewModel: BaseViewModel {
    var showEditor = false
    var newPost = SocialPost(title: "", platform: .twitter, status: .idea, date: Date(), content: "", views: 0, likes: 0)
    var selectedPost: SocialPost?
    var selectedDate: Date?
    
    private let socialPostRepository: SocialPostRepository
    
    init(socialPostRepository: SocialPostRepository) {
        self.socialPostRepository = socialPostRepository
    }
    
    func savePost(_ post: SocialPost) async {
        do {
            try await socialPostRepository.save(post)
            Logger.log("Post saved: \(post.title)", category: Logger.general)
        } catch {
            ErrorHandler.shared.handle(error, context: "SocialDashboardViewModel.savePost")
        }
    }
    
    func deletePost(_ post: SocialPost) async {
        do {
            try await socialPostRepository.delete(post)
            Logger.log("Post deleted", category: Logger.general)
        } catch {
            ErrorHandler.shared.handle(error, context: "SocialDashboardViewModel.deletePost")
        }
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
