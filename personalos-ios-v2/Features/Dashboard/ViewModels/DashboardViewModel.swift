import SwiftUI
import SwiftData
import Combine

@Observable
@MainActor
class DashboardViewModel: BaseViewModel {
    var showGlobalSearch: Bool = false
    var searchText: String = ""

    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    func dailyBriefing(steps: Int) -> String {
        return "Today: \(steps) steps taken."
    }
    
    let quickActions = [
        (title: "Add Note", subtitle: "捕捉想法并同步到知识库", icon: "note.text.badge.plus", color: AppTheme.mistBlue),
        (title: "Log Trade", subtitle: "记录一笔新的交易复盘", icon: "chart.bar.xaxis", color: AppTheme.almond),
        (title: "Focus", subtitle: "开启 25 分钟专注会话", icon: "moon.stars.fill", color: AppTheme.lavender),
        (title: "Scan", subtitle: "快速扫描并存档文档", icon: "qrcode.viewfinder", color: AppTheme.primaryText)
    ]

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
