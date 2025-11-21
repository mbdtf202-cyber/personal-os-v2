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
    
    var recentTasks: [TodoItem] = []
    var recentPosts: [SocialPost] = []
    var recentTrades: [TradeRecord] = []
    
    private let todoRepository: TodoRepository
    private let modelContext: ModelContext
    
    init(todoRepository: TodoRepository, modelContext: ModelContext) {
        self.todoRepository = todoRepository
        self.modelContext = modelContext
    }
    
    func loadRecentData() async {
        await loadRecentTasks()
        await loadRecentPosts()
        await loadRecentTrades()
    }
    
    private func loadRecentTasks() async {
        var descriptor = FetchDescriptor<TodoItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        do {
            recentTasks = try modelContext.fetch(descriptor)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.loadRecentTasks")
        }
    }
    
    private func loadRecentPosts() async {
        var descriptor = FetchDescriptor<SocialPost>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        do {
            recentPosts = try modelContext.fetch(descriptor)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.loadRecentPosts")
        }
    }
    
    private func loadRecentTrades() async {
        var descriptor = FetchDescriptor<TradeRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 10
        
        do {
            recentTrades = try modelContext.fetch(descriptor)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.loadRecentTrades")
        }
    }

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
    
    func calculateActivityData() async -> [(String, Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        var activityData: [(String, Double)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            // 使用数据库层面的过滤，而不是内存过滤
            let completedTasks = try? modelContext.fetch(
                FetchDescriptor<TodoItem>(
                    predicate: #Predicate { task in
                        task.isCompleted && task.createdAt >= dayStart && task.createdAt < dayEnd
                    }
                )
            ).count ?? 0
            
            let postsCount = try? modelContext.fetch(
                FetchDescriptor<SocialPost>(
                    predicate: #Predicate { post in
                        post.date >= dayStart && post.date < dayEnd
                    }
                )
            ).count ?? 0
            
            let tradesCount = try? modelContext.fetch(
                FetchDescriptor<TradeRecord>(
                    predicate: #Predicate { trade in
                        trade.date >= dayStart && trade.date < dayEnd
                    }
                )
            ).count ?? 0
            
            let totalActivity = Double(completedTasks + postsCount + tradesCount)
            let dayIndex = calendar.component(.weekday, from: date)
            let dayName = weekDays[(dayIndex + 5) % 7]
            
            activityData.append((dayName, totalActivity))
        }
        
        return activityData
    }

    func addTask(title: String) async {
        let item = TodoItem(title: title)
        do {
            try await todoRepository.save(item)
            Logger.log("Task added: \(title)", category: Logger.general)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.addTask")
        }
    }

    func toggleTask(_ task: TodoItem) async {
        task.isCompleted.toggle()
        HapticsManager.shared.light()
        do {
            try await todoRepository.save(task)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.toggleTask")
        }
    }

    func deleteTask(_ task: TodoItem) async {
        do {
            try await todoRepository.delete(task)
            Logger.log("Task deleted", category: Logger.general)
        } catch {
            ErrorHandler.shared.handle(error, context: "DashboardViewModel.deleteTask")
        }
    }
}
