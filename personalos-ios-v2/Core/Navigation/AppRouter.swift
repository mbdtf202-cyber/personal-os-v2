import SwiftUI
import Observation

@Observable
@MainActor
class AppRouter {
    enum Tab {
        case dashboard  // 🏠 总览 + 健康
        case growth     // 🚀 成长 (Project + Knowledge + Tools)
        case social     // 💬 社媒
        case wealth     // 💰 财富 (Trading)
        case news       // 📰 资讯
    }
    
    var selectedTab: Tab = .dashboard
    var showGlobalSearch: Bool = false
    
    func navigate(to tab: Tab) {
        selectedTab = tab
    }
    
    func toggleGlobalSearch() {
        showGlobalSearch.toggle()
    }
}
