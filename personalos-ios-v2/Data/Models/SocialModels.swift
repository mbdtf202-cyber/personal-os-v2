import SwiftUI
import SwiftData

// Models moved to UnifiedSchema.swift

extension SocialPost {
    static var defaultPosts: [SocialPost] {
        [
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
