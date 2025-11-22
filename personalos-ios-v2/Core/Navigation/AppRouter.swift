import SwiftUI
import Observation

@Observable
@MainActor
class AppRouter {
    var selectedTab: Tab = .dashboard
    var navigationPath = NavigationPath()
    
    enum Tab: Hashable {
        case dashboard
        case growth
        case social
        case wealth
        case news
    }
    
    func navigate(to tab: Tab) {
        selectedTab = tab
    }
    
    func push<T: Hashable>(_ value: T) {
        navigationPath.append(value)
    }
    
    func pop() {
        if !navigationPath.isEmpty {
            navigationPath.removeLast()
        }
    }
    
    func popToRoot() {
        navigationPath = NavigationPath()
    }
}
