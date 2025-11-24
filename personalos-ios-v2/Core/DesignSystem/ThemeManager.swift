import SwiftUI
import UIKit
import Observation

/// ✅ P0 Task 20: Migrated from ObservableObject to @Observable
/// Requirement 18.1: Use @Observable macro for state management
@MainActor
@Observable
class ThemeManager {
    static let shared = ThemeManager()
    
    var currentTheme: AppThemeMode = .system
    var currentStyle: ThemeStyle = .glass
    var performanceMode: PerformanceMode = .standard
    
    private init() {
        loadSavedTheme()
        detectPerformanceCapability()
    }
    
    func applyTheme(_ theme: AppThemeMode) {
        currentTheme = theme
        saveTheme(theme)
        
        configureUIKitAppearance()
        configureSwiftUIEnvironment()
    }
    
    private func configureUIKitAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        
        switch currentTheme {
        case .light:
            appearance.backgroundColor = UIColor(AppTheme.background)
            appearance.titleTextAttributes = [.foregroundColor: UIColor(AppTheme.primaryText)]
        case .dark:
            appearance.backgroundColor = UIColor(Color(hex: "1C1C1E"))
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        case .system:
            appearance.backgroundColor = UIColor.systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        }
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // TabBar
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        
        switch currentTheme {
        case .light:
            tabBarAppearance.backgroundColor = UIColor(AppTheme.background)
        case .dark:
            tabBarAppearance.backgroundColor = UIColor(Color(hex: "1C1C1E"))
        case .system:
            tabBarAppearance.backgroundColor = UIColor.systemBackground
        }
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    private func configureSwiftUIEnvironment() {
        // This will be applied through environment in App
    }
    
    private func loadSavedTheme() {
        if let savedTheme = UserDefaults.standard.string(forKey: "app_theme"),
           let theme = AppThemeMode(rawValue: savedTheme) {
            currentTheme = theme
        }
        if let savedStyle = UserDefaults.standard.string(forKey: "app_style"),
           let style = ThemeStyle(rawValue: savedStyle) {
            currentStyle = style
            AppTheme.apply(style: style)
        }
    }
    
    private func saveTheme(_ theme: AppThemeMode) {
        UserDefaults.standard.set(theme.rawValue, forKey: "app_theme")
    }
    
    func applyStyle(_ style: ThemeStyle) {
        currentStyle = style
        AppTheme.apply(style: style)
        UserDefaults.standard.set(style.rawValue, forKey: "app_style")
    }
    
    private func detectPerformanceCapability() {
        let processInfo = ProcessInfo.processInfo
        let physicalMemory = processInfo.physicalMemory
        
        // Devices with < 3GB RAM use reduced performance mode
        if physicalMemory < 3_000_000_000 {
            performanceMode = .reduced
        } else {
            performanceMode = .standard
        }
    }
    
    func shouldUseReducedMotion() -> Bool {
        return performanceMode == .reduced || UIAccessibility.isReduceMotionEnabled
    }
    
    func shouldUseReducedTransparency() -> Bool {
        return performanceMode == .reduced || UIAccessibility.isReduceTransparencyEnabled
    }
}

enum AppThemeMode: String, CaseIterable {
    case light = "light"
    case dark = "dark"
    case system = "system"
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}

enum PerformanceMode {
    case standard
    case reduced
}
