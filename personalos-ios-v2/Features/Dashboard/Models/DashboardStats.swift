import Foundation

struct DashboardStats {
    let pendingTasksCount: Int
    let completedTasksCount: Int
    let todaySteps: Int
    let weeklyActivity: [(String, Double)]
    let recentPostsCount: Int
    let recentTradesCount: Int
    
    static let empty = DashboardStats(
        pendingTasksCount: 0,
        completedTasksCount: 0,
        todaySteps: 0,
        weeklyActivity: [],
        recentPostsCount: 0,
        recentTradesCount: 0
    )
}

@MainActor
class DashboardStatsCalculator {
    static func calculate(
        tasks: [TodoItem],
        posts: [SocialPost],
        trades: [TradeRecord]
    ) -> DashboardStats {
        let pendingTasks = tasks.filter { !$0.isCompleted }.count
        let completedTasks = tasks.filter { $0.isCompleted }.count
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekDays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        var activityData: [(String, Double)] = []
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: dayStart)!
            
            let completedTasksCount = tasks.filter { task in
                task.isCompleted && task.createdAt >= dayStart && task.createdAt < dayEnd
            }.count
            
            let postsCount = posts.filter { post in
                post.date >= dayStart && post.date < dayEnd
            }.count
            
            let tradesCount = trades.filter { trade in
                trade.date >= dayStart && trade.date < dayEnd
            }.count
            
            let totalActivity = Double(completedTasksCount + postsCount + tradesCount)
            let dayIndex = calendar.component(.weekday, from: date)
            let dayName = weekDays[(dayIndex + 5) % 7]
            
            activityData.append((dayName, totalActivity))
        }
        
        return DashboardStats(
            pendingTasksCount: pendingTasks,
            completedTasksCount: completedTasks,
            todaySteps: 0,
            weeklyActivity: activityData,
            recentPostsCount: posts.count,
            recentTradesCount: trades.count
        )
    }
}
