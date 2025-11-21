import SwiftUI

struct EmptyStateView: View {
    let config: EmptyStateConfig
    
    var body: some View {
        VStack(spacing: 24) {
            // Icon/Illustration
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                config.accentColor.opacity(0.1),
                                config.accentColor.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: config.icon)
                    .font(.system(size: 48, weight: .light))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [config.accentColor, config.accentColor.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            .animateOnAppear()
            
            // Text Content
            VStack(spacing: 12) {
                Text(config.title)
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(config.message)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .animateOnAppear(delay: 0.1)
            
            // Action Button
            if let action = config.action {
                Button(action: action.handler) {
                    HStack(spacing: 8) {
                        if let icon = action.icon {
                            Image(systemName: icon)
                        }
                        Text(action.title)
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(config.accentColor)
                    .cornerRadius(12)
                }
                .bounceOnTap()
                .animateOnAppear(delay: 0.2)
            }
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EmptyStateConfig {
    let icon: String
    let title: String
    let message: String
    let accentColor: Color
    let action: EmptyStateAction?
    
    init(
        icon: String,
        title: String,
        message: String,
        accentColor: Color = AppTheme.mistBlue,
        action: EmptyStateAction? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.accentColor = accentColor
        self.action = action
    }
}

struct EmptyStateAction {
    let title: String
    let icon: String?
    let handler: () -> Void
    
    init(title: String, icon: String? = nil, handler: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.handler = handler
    }
}

// MARK: - Preset Configurations

extension EmptyStateConfig {
    static func noTasks(onAdd: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "checkmark.seal",
            title: "All Clear!",
            message: "You have no pending tasks. Time to relax or add a new one.",
            accentColor: AppTheme.matcha,
            action: EmptyStateAction(title: "Add Task", icon: "plus.circle", handler: onAdd)
        )
    }
    
    static func noNews(onRefresh: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "newspaper",
            title: "No News Available",
            message: "Pull to refresh or check your internet connection.",
            accentColor: AppTheme.mistBlue,
            action: EmptyStateAction(title: "Refresh", icon: "arrow.clockwise", handler: onRefresh)
        )
    }
    
    static func noPosts(onCreate: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "doc.text",
            title: "No Posts Yet",
            message: "Start creating content to build your audience.",
            accentColor: AppTheme.lavender,
            action: EmptyStateAction(title: "Create Post", icon: "plus", handler: onCreate)
        )
    }
    
    static func noTrades(onLog: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "chart.line.uptrend.xyaxis",
            title: "No Trades Logged",
            message: "Start tracking your trades to analyze your performance.",
            accentColor: AppTheme.almond,
            action: EmptyStateAction(title: "Log Trade", icon: "plus.circle", handler: onLog)
        )
    }
    
    static func noProjects(onCreate: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "hammer",
            title: "No Projects",
            message: "Create your first project to start building something amazing.",
            accentColor: AppTheme.mistBlue,
            action: EmptyStateAction(title: "New Project", icon: "plus", handler: onCreate)
        )
    }
    
    static func searchNoResults(query: String) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "magnifyingglass",
            title: "No Results Found",
            message: "Try adjusting your search terms or filters.",
            accentColor: AppTheme.secondaryText
        )
    }
    
    static func networkError(onRetry: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "wifi.slash",
            title: "Connection Error",
            message: "Unable to connect to the server. Please check your internet connection.",
            accentColor: AppTheme.coral,
            action: EmptyStateAction(title: "Try Again", icon: "arrow.clockwise", handler: onRetry)
        )
    }
    
    static func permissionDenied(message: String, onSettings: @escaping () -> Void) -> EmptyStateConfig {
        EmptyStateConfig(
            icon: "lock.shield",
            title: "Permission Required",
            message: message,
            accentColor: AppTheme.almond,
            action: EmptyStateAction(title: "Open Settings", icon: "gear", handler: onSettings)
        )
    }
}

#Preview {
    EmptyStateView(config: .noTasks(onAdd: {}))
}
