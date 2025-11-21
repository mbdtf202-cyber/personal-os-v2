import SwiftUI
import SwiftData

@Model
final class SocialPost {
    var id: UUID
    var title: String
    var platform: SocialPlatform
    var status: PostStatus
    var date: Date
    var content: String
    var views: Int
    var likes: Int

    init(id: UUID = UUID(), title: String, platform: SocialPlatform, status: PostStatus, date: Date, content: String, views: Int, likes: Int) {
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

extension SocialPost {
    static var defaultPosts: [SocialPost] {
        [
            SocialPost(
                title: "iOS 开发技巧分享",
                platform: .xiaohongshu,
                status: .draft,
                date: Date(),
                content: "今天分享一个 SwiftUI 的实用技巧...",
                views: 0,
                likes: 0
            ),
            SocialPost(
                title: "PersonalOS 项目进展",
                platform: .twitter,
                status: .scheduled,
                date: Date().addingTimeInterval(86400),
                content: "正在开发一个全新的个人操作系统 #SwiftUI #iOS",
                views: 0,
                likes: 0
            ),
            SocialPost(
                title: "技术博客：MVVM 架构实践",
                platform: .blog,
                status: .idea,
                date: Date().addingTimeInterval(172800),
                content: "# MVVM 架构在 SwiftUI 中的应用\n\n本文将详细介绍...",
                views: 0,
                likes: 0
            )
        ]
    }
}
