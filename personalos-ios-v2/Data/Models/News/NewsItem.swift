import Foundation
import SwiftData

/// Data source type for news items
enum NewsDataSource: String, Codable {
    case real = "real"
    case demo = "demo"
    case mock = "mock"
    
    var displayName: String {
        switch self {
        case .real: return "Live Data"
        case .demo: return "Demo Content"
        case .mock: return "Mock Data"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .real: return "green"
        case .demo: return "orange"
        case .mock: return "gray"
        }
    }
}

@Model
final class NewsItem {
    var id: UUID
    var source: String
    var title: String
    var summary: String
    var category: String
    var image: String
    var imageURL: String?
    var date: Date
    var url: URL?
    
    // ✅ P0 Fix: Data source identification (Requirement 14.1)
    var dataSource: String = NewsDataSource.demo.rawValue
    
    // ✅ P0 Fix: Stable canonical ID (Requirement 16.1)
    var canonicalID: String
    
    var dataSourceType: NewsDataSource {
        NewsDataSource(rawValue: dataSource) ?? .demo
    }

    init(id: UUID = UUID(), source: String, title: String, summary: String, category: String, image: String, imageURL: String? = nil, date: Date, url: URL? = nil, dataSource: NewsDataSource = .demo, canonicalID: String? = nil) {
        self.id = id
        self.source = source
        self.title = title
        self.summary = summary
        self.category = category
        self.image = image
        self.imageURL = imageURL
        self.date = date
        self.url = url
        self.dataSource = dataSource.rawValue
        
        // ✅ Use URL as stable identifier, fallback to title+source hash
        if let canonicalID = canonicalID {
            self.canonicalID = canonicalID
        } else if let url = url {
            self.canonicalID = url.absoluteString
        } else {
            self.canonicalID = "\(source):\(title)".hashValue.description
        }
    }
    
    /// Check if this item matches another by canonical ID
    func matches(_ other: NewsItem) -> Bool {
        return self.canonicalID == other.canonicalID
    }
}
