import SwiftUI
import SwiftData

@Model
final class RSSFeed {
    var id: UUID
    var name: String
    var url: String
    var category: String
    var isEnabled: Bool
    var lastFetched: Date?
    
    init(id: UUID = UUID(), name: String, url: String, category: String = "General", isEnabled: Bool = true, lastFetched: Date? = nil) {
        self.id = id
        self.name = name
        self.url = url
        self.category = category
        self.isEnabled = isEnabled
        self.lastFetched = lastFetched
    }
    
    static let defaultFeeds: [RSSFeed] = [
        RSSFeed(name: "Hacker News", url: "https://news.ycombinator.com/rss", category: "Tech"),
        RSSFeed(name: "TechCrunch", url: "https://techcrunch.com/feed/", category: "Tech"),
        RSSFeed(name: "The Verge", url: "https://www.theverge.com/rss/index.xml", category: "Tech"),
        RSSFeed(name: "CSS-Tricks", url: "https://css-tricks.com/feed/", category: "Dev"),
        RSSFeed(name: "SwiftLee", url: "https://www.avanderlee.com/feed/", category: "Swift")
    ]
}
