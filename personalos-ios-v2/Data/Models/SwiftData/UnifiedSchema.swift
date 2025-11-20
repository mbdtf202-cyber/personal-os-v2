import SwiftUI
import SwiftData

// MARK: - TodoItem
@Model
final class TodoItem {
    var title: String
    var createdAt: Date
    var isCompleted: Bool
    var category: String
    var priority: Int

    init(title: String, createdAt: Date = .now, isCompleted: Bool = false, category: String = "Life", priority: Int = 1) {
        self.title = title
        self.createdAt = createdAt
        self.isCompleted = isCompleted
        self.category = category
        self.priority = priority
    }
}

// MARK: - HealthLog
@Model
final class HealthLog {
    var id: UUID
    var date: Date
    var sleepHours: Double
    var moodScore: Int
    var steps: Int
    var energyLevel: Int

    init(id: UUID = UUID(), date: Date = .now, sleepHours: Double = 0, moodScore: Int = 5, steps: Int = 0, energyLevel: Int = 50) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.moodScore = moodScore
        self.steps = steps
        self.energyLevel = energyLevel
    }
}

// MARK: - SocialPost
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

// MARK: - ProjectItem
@Model
final class ProjectItem {
    var id: UUID
    var name: String
    var details: String // Renamed from description to avoid potential conflicts
    var language: String
    var stars: Int
    var status: ProjectStatus
    var progress: Double

    init(id: UUID = UUID(), name: String, details: String, language: String, stars: Int, status: ProjectStatus, progress: Double) {
        self.id = id
        self.name = name
        self.details = details
        self.language = language
        self.stars = stars
        self.status = status
        self.progress = progress
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

// MARK: - NewsItem
@Model
final class NewsItem {
    var id: UUID
    var source: String
    var title: String
    var summary: String
    var category: String
    var image: String
    var date: Date
    var url: URL?

    init(id: UUID = UUID(), source: String, title: String, summary: String, category: String, image: String, date: Date, url: URL? = nil) {
        self.id = id
        self.source = source
        self.title = title
        self.summary = summary
        self.category = category
        self.image = image
        self.date = date
        self.url = url
    }
}

// MARK: - TradeRecord
@Model
final class TradeRecord {
    var id: String
    var symbol: String
    var type: TradeType
    var price: Double
    var quantity: Double
    var assetType: AssetType
    var emotion: TradeEmotion
    var note: String
    var date: Date

    init(id: String = UUID().uuidString, symbol: String, type: TradeType, price: Double, quantity: Double, assetType: AssetType, emotion: TradeEmotion, note: String, date: Date = Date()) {
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

enum TradeType: String, CaseIterable, Codable {
    case buy = "Buy"
    case sell = "Sell"
}

enum TradeEmotion: String, CaseIterable, Codable {
    case excited = "Excited"
    case fearful = "Fearful"
    case neutral = "Neutral"
    case revenge = "Revenge"

    var color: Color {
        switch self {
        case .excited: return .orange
        case .fearful: return .purple
        case .neutral: return .blue
        case .revenge: return .red
        }
    }
}

// MARK: - AssetItem
@Model
final class AssetItem {
    var id: UUID
    var symbol: String
    var name: String
    var quantity: Double
    var currentPrice: Double
    var avgCost: Double
    var type: AssetType

    init(id: UUID = UUID(), symbol: String, name: String, quantity: Double, currentPrice: Double, avgCost: Double, type: AssetType) {
        self.id = id
        self.symbol = symbol
        self.name = name
        self.quantity = quantity
        self.currentPrice = currentPrice
        self.avgCost = avgCost
        self.type = type
    }
    
    @Transient var marketValue: Double { quantity * currentPrice }
    @Transient var pnl: Double { (currentPrice - avgCost) * quantity }
    @Transient var pnlPercent: Double { avgCost == 0 ? 0 : (currentPrice - avgCost) / avgCost }
}

enum AssetType: String, CaseIterable, Codable {
    case stock, crypto, forex

    var icon: String {
        switch self {
        case .stock: return "building.columns.fill"
        case .crypto: return "bitcoinsign.circle.fill"
        case .forex: return "dollarsign.arrow.circlepath"
        }
    }

    var label: String {
        switch self {
        case .stock: return "Stock"
        case .crypto: return "Crypto"
        case .forex: return "Forex"
        }
    }
}
