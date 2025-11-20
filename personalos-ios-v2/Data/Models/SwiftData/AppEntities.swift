import SwiftUI
import SwiftData

@Model
final class TodoItem {
    var id: UUID
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var category: String
    var priority: Int

    init(
        id: UUID = UUID(),
        title: String,
        createdAt: Date = .now,
        isCompleted: Bool = false,
        category: String = "Life",
        priority: Int = 1
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.category = category
        self.priority = priority
    }
}

@Model
final class TradeRecord: Identifiable {
    var id: UUID
    var symbol: String
    var type: TradeType
    var price: Double
    var quantity: Double
    var assetType: AssetType
    var emotion: TradeEmotion
    var note: String
    var date: Date

    init(
        id: UUID = UUID(),
        symbol: String,
        type: TradeType,
        price: Double,
        quantity: Double,
        assetType: AssetType,
        emotion: TradeEmotion,
        note: String = "",
        date: Date = Date()
    ) {
        self.id = id
        self.symbol = symbol
        self.type = type
        self.price = price
        self.quantity = quantity
        self.assetType = assetType
        self.emotion = emotion
        self.note = note
        self.date = date
    }
}

@Model
final class HealthLog {
    var id: UUID
    var date: Date
    var sleepHours: Double
    var moodScore: Int
    var steps: Int
    var energyLevel: Int

    init(
        id: UUID = UUID(),
        date: Date = .now,
        sleepHours: Double = 0,
        moodScore: Int = 5,
        steps: Int = 0,
        energyLevel: Int = 50
    ) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.moodScore = moodScore
        self.steps = steps
        self.energyLevel = energyLevel
    }
}

@Model
final class HabitItem {
    var id: UUID
    var icon: String
    var title: String
    var colorHex: String
    var isCompleted: Bool = false

    var color: Color {
        Color(hex: colorHex)
    }

    init(id: UUID = UUID(), icon: String, title: String, color: Color, isCompleted: Bool = false) {
        self.id = id
        self.icon = icon
        self.title = title
        self.colorHex = color.toHex()
        self.isCompleted = isCompleted
    }
}

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

    init(
        id: UUID = UUID(),
        title: String,
        platform: SocialPlatform,
        status: PostStatus,
        date: Date,
        content: String,
        views: Int,
        likes: Int
    ) {
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

@Model
final class ProjectItem {
    var id: UUID
    var name: String
    var description: String
    var language: String
    var stars: Int
    var status: ProjectStatus
    var progress: Double

    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        language: String,
        stars: Int,
        status: ProjectStatus,
        progress: Double
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.language = language
        self.stars = stars
        self.status = status
        self.progress = progress
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

enum ProjectStatus: String, CaseIterable, Codable {
    case active = "Active"
    case idea = "Idea"
    case done = "Done"

    var color: Color {
        switch self {
        case .active: return AppTheme.mistBlue
        case .idea: return AppTheme.almond
        case .done: return AppTheme.matcha
        }
    }
}

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

extension HabitItem {
    static var defaultHabits: [HabitItem] {
        [
            HabitItem(icon: "drop.fill", title: "Drink 2L Water", color: AppTheme.mistBlue),
            HabitItem(icon: "book.fill", title: "Read 30 mins", color: AppTheme.lavender),
            HabitItem(icon: "figure.mind.and.body", title: "Meditation", color: AppTheme.matcha),
            HabitItem(icon: "moon.stars.fill", title: "Sleep Early", color: AppTheme.primaryText)
        ]
    }
}

extension Color {
    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components else { return "89C4F4" }
        let r = Int(components[0] * 255.0)
        let g = Int(components[1] * 255.0)
        let b = Int(components[2] * 255.0)
        return String(format: "%02X%02X%02X", r, g, b)
    }
}
