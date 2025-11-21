import SwiftUI

enum SocialPlatform: String, CaseIterable, Codable {
    case xiaohongshu = "RedBook"
    case twitter = "X"
    case weibo = "Weibo"
    case wechat = "WeChat"
    case blog = "Blog"

    var color: Color {
        switch self {
        case .xiaohongshu: return Color(hex: "FF2442")
        case .twitter: return Color.black
        case .weibo: return Color(hex: "E6162D")
        case .wechat: return Color(hex: "07C160")
        case .blog: return AppTheme.mistBlue
        }
    }

    var icon: String {
        switch self {
        case .xiaohongshu: return "book.fill"
        case .twitter: return "xmark"
        case .weibo: return "w.circle.fill"
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
