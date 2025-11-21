import Foundation
import SwiftData

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

    init(id: UUID = UUID(), source: String, title: String, summary: String, category: String, image: String, imageURL: String? = nil, date: Date, url: URL? = nil) {
        self.id = id
        self.source = source
        self.title = title
        self.summary = summary
        self.category = category
        self.image = image
        self.imageURL = imageURL
        self.date = date
        self.url = url
    }
}
