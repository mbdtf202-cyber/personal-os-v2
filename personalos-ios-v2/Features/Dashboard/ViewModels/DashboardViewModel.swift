import SwiftUI
import SwiftData
import Combine

struct QuickAction: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    let targetTab: AppRouter.Tab?
    let action: QuickActionType
    
    enum QuickActionType {
        case navigate
        case showSheet
    }
}

@Observable
@MainActor
class DashboardViewModel: BaseViewModel {
    var showGlobalSearch: Bool = false
    var searchText: String = ""
    var showFocusTimer: Bool = false
    var showNewPostSheet: Bool = false
    var showNewTradeSheet: Bool = false

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    func dailyBriefing(tasks: [TodoItem], steps: Int) -> String {
        let pendingTasks = tasks.filter { !$0.isCompleted }.count
        if pendingTasks == 0 {
            return "You're all caught up! \(steps) steps today."
        } else {
            return "You have \(pendingTasks) tasks pending. \(steps) steps today."
        }
    }
    
    let quickActions: [QuickAction] = [
        QuickAction(title: "Add Note", subtitle: "捕捉想法并同步到知识库", icon: "note.text.badge.plus", color: AppTheme.mistBlue, targetTab: .social, action: .showSheet),
        QuickAction(title: "Log Trade", subtitle: "记录一笔新的交易复盘", icon: "chart.bar.xaxis", color: AppTheme.almond, targetTab: .wealth, action: .showSheet),
        QuickAction(title: "Focus", subtitle: "开启 25 分钟专注会话", icon: "moon.stars.fill", color: AppTheme.lavender, targetTab: nil, action: .showSheet),
        QuickAction(title: "Scan", subtitle: "快速扫描并存档文档", icon: "qrcode.viewfinder", color: AppTheme.primaryText, targetTab: .growth, action: .navigate)
    ]
    
    func handleQuickAction(_ action: QuickAction, router: AppRouter) {
        switch action.title {
        case "Add Note":
            showNewPostSheet = true
        case "Log Trade":
            showNewTradeSheet = true
        case "Focus":
            showFocusTimer = true
        case "Scan":
            if let tab = action.targetTab {
                router.navigate(to: tab)
            }
        default:
            break
        }
    }
    
    func calculateActivityData(tasks: [TodoItem], posts: [SocialPost], trades: [TradeRecord]) -> [(String, Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        var activityData: [(String, Double)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let completedTasks = tasks.filter { task in
                task.isCompleted && task.createdAt >= dayStart && task.createdAt < dayEnd
            }.count
            
            let postsCount = posts.filter { post in
                post.date >= dayStart && post.date < dayEnd
            }.count
            
            let tradesCount = trades.filter { trade in
                trade.date >= dayStart && trade.date < dayEnd
            }.count
            
            let totalActivity = Double(completedTasks + postsCount + tradesCount)
            let dayIndex = calendar.component(.weekday, from: date)
            let dayName = weekDays[(dayIndex + 5) % 7] // Adjust for Monday start
            
            activityData.append((dayName, totalActivity))
        }
        
        return activityData
    }

    func addTask(title: String, context: ModelContext) {
        let item = TodoItem(title: title)
        context.insert(item)

        do {
            try context.save()
        } catch {
            assertionFailure("Failed to save new task: \(error.localizedDescription)")
        }
    }

    func toggleTask(_ task: TodoItem, context: ModelContext) {
        task.isCompleted.toggle()
        HapticsManager.shared.light()
        try? context.save()
    }

    func deleteTask(_ task: TodoItem, context: ModelContext) {
        context.delete(task)
        try? context.save()
    }
}
