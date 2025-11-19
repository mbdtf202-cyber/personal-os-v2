import SwiftUI
import Observation

@Observable
class ContentManager {
    var posts: [SocialPost] = []
    
    init() {
        loadPosts()
    }
    
    func loadPosts() {
        if let data = UserDefaults.standard.data(forKey: "socialPosts"),
           let decoded = try? JSONDecoder().decode([SocialPost].self, from: data) {
            posts = decoded
        } else {
            posts = [
                SocialPost(
                    title: "Personal OS 开发日记 #1",
                    platform: .wechat,
                    status: .published,
                    date: Date().addingTimeInterval(-86400 * 2),
                    content: "今天开始了 Personal OS 的架构设计...",
                    views: 1205,
                    likes: 89
                ),
                SocialPost(
                    title: "SwiftUI Glassmorphism Tutorial",
                    platform: .twitter,
                    status: .scheduled,
                    date: Date().addingTimeInterval(86400),
                    content: "Check out this new glass effect modifier! #SwiftUI #iOSDev",
                    views: 0,
                    likes: 0
                ),
                SocialPost(
                    title: "如何用 30 天养成早起习惯",
                    platform: .xiaohongshu,
                    status: .draft,
                    date: Date(),
                    content: "早起的第一步不是闹钟，而是...",
                    views: 0,
                    likes: 0
                ),
                SocialPost(
                    title: "Next Project Idea: AI Agent",
                    platform: .twitter,
                    status: .idea,
                    date: Date(),
                    content: "",
                    views: 0,
                    likes: 0
                )
            ]
        }
    }
    
    var upcomingPosts: [SocialPost] {
        posts.filter { $0.status == .scheduled }.sorted { $0.date < $1.date }
    }
    
    var drafts: [SocialPost] {
        posts.filter { $0.status == .draft || $0.status == .idea }
    }
    
    func addPost(_ post: SocialPost) {
        posts.append(post)
        savePosts()
    }
    
    func updatePost(_ post: SocialPost) {
        if let index = posts.firstIndex(where: { $0.id == post.id }) {
            posts[index] = post
            savePosts()
        }
    }
    
    func deletePost(_ post: SocialPost) {
        posts.removeAll { $0.id == post.id }
        savePosts()
    }
    
    func savePosts() {
        if let encoded = try? JSONEncoder().encode(posts) {
            UserDefaults.standard.set(encoded, forKey: "socialPosts")
        }
    }
}

// MARK: - Models

struct SocialPost: Identifiable, Codable {
    var id: String
    var title: String
    var platform: SocialPlatform
    var status: PostStatus
    var date: Date
    var content: String
    var views: Int
    var likes: Int
    
    init(id: String = UUID().uuidString, title: String, platform: SocialPlatform, status: PostStatus, date: Date, content: String, views: Int, likes: Int) {
        self.id = id
        self.title = title
        self.platform = platform
        self.status = status
        self.date = date
        self.content = content
        self.views = views
        self.likes = likes
    }
}

enum SocialPlatform: String, CaseIterable, Codable {
    case xiaohongshu = "RedBook"
    case twitter = "X"
    case wechat = "WeChat"
    case blog = "Blog"
    
    var color: Color {
        switch self {
        case .xiaohongshu: return Color(hex: "FF2442")
        case .twitter: return Color.black
        case .wechat: return Color(hex: "07C160")
        case .blog: return AppTheme.mistBlue
        }
    }
    
    var icon: String {
        switch self {
        case .xiaohongshu: return "book.fill"
        case .twitter: return "xmark"
        case .wechat: return "message.fill"
        case .blog: return "doc.text.fill"
        }
    }
}

enum PostStatus: String, CaseIterable, Codable {
    case idea = "Idea"
    case draft = "Draft"
    case scheduled = "Scheduled"
    case published = "Published"
    
    var color: Color {
        switch self {
        case .idea: return .gray
        case .draft: return .orange
        case .scheduled: return .blue
        case .published: return .green
        }
    }
}
