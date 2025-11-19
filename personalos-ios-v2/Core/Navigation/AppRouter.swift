import SwiftUI
import Observation

@Observable
@MainActor
class AppRouter {
    enum Tab {
        case dashboard
        case health
        case training
        case trading
        case social
        case news
        case projects
        case tools
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
