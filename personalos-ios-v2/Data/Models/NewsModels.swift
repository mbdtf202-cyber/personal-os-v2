import Foundation

struct NewsItem: Identifiable {
    let id = UUID()
    var source: String
    var title: String
    var summary: String
    var category: String
    var image: String
    var date: Date
    var url: URL?
}
