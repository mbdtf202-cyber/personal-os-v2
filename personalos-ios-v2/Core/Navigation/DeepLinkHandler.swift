import Foundation
import SwiftUI

enum DeepLink: Equatable {
    case dashboard
    case health
    case habits
    case project(id: String)
    case projectList
    case news(category: String?)
    case newsArticle(id: String)
    case trading
    case tradeDetail(id: String)
    case social
    case socialPost(id: String)
    case training
    case snippet(id: String)
    case tools
    case settings
    case search(query: String)
    
    init?(url: URL) {
        guard url.scheme == "personalos" else { return nil }
        
        let path = url.host ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems
        
        switch path {
        case "dashboard":
            self = .dashboard
        case "health":
            self = .health
        case "habits":
            self = .habits
        case "projects":
            if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                self = .project(id: id)
            } else {
                self = .projectList
            }
        case "news":
            let category = queryItems?.first(where: { $0.name == "category" })?.value
            if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                self = .newsArticle(id: id)
            } else {
                self = .news(category: category)
            }
        case "trading":
            if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                self = .tradeDetail(id: id)
            } else {
                self = .trading
            }
        case "social":
            if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                self = .socialPost(id: id)
            } else {
                self = .social
            }
        case "training":
            if let id = queryItems?.first(where: { $0.name == "id" })?.value {
                self = .snippet(id: id)
            } else {
                self = .training
            }
        case "tools":
            self = .tools
        case "settings":
            self = .settings
        case "search":
            if let query = queryItems?.first(where: { $0.name == "q" })?.value {
                self = .search(query: query)
            } else {
                return nil
            }
        default:
            return nil
        }
    }
    
    var url: URL? {
        var components = URLComponents()
        components.scheme = "personalos"
        
        switch self {
        case .dashboard:
            components.host = "dashboard"
        case .health:
            components.host = "health"
        case .habits:
            components.host = "habits"
        case .project(let id):
            components.host = "projects"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .projectList:
            components.host = "projects"
        case .news(let category):
            components.host = "news"
            if let category = category {
                components.queryItems = [URLQueryItem(name: "category", value: category)]
            }
        case .newsArticle(let id):
            components.host = "news"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .trading:
            components.host = "trading"
        case .tradeDetail(let id):
            components.host = "trading"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .social:
            components.host = "social"
        case .socialPost(let id):
            components.host = "social"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .training:
            components.host = "training"
        case .snippet(let id):
            components.host = "training"
            components.queryItems = [URLQueryItem(name: "id", value: id)]
        case .tools:
            components.host = "tools"
        case .settings:
            components.host = "settings"
        case .search(let query):
            components.host = "search"
            components.queryItems = [URLQueryItem(name: "q", value: query)]
        }
        
        return components.url
    }
}

@MainActor
@Observable
class DeepLinkHandler {
    var currentDeepLink: DeepLink?
    
    func handle(_ url: URL) {
        guard let deepLink = DeepLink(url: url) else {
            Logger.warning("Invalid deep link: \(url)", category: Logger.general)
            return
        }
        
        currentDeepLink = deepLink
        navigate(to: deepLink)
    }
    
    private func navigate(to deepLink: DeepLink) {
        // This will be handled by the router
        NotificationCenter.default.post(
            name: .deepLinkReceived,
            object: nil,
            userInfo: ["deepLink": deepLink]
        )
    }
}

extension Notification.Name {
    static let deepLinkReceived = Notification.Name("deepLinkReceived")
}
