import SwiftUI

@Observable
class DashboardViewModel {
    var showGlobalSearch: Bool = false
    var searchText: String = ""
    var tasks: [SchemaV1.TodoItem] = []
    
    var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Good Night"
        }
    }
    
    let quickActions = [
        (title: "Add Note", subtitle: "捕捉想法并同步到知识库", icon: "note.text.badge.plus", color: AppTheme.mistBlue),
        (title: "Log Trade", subtitle: "记录一笔新的交易复盘", icon: "chart.bar.xaxis", color: AppTheme.almond),
        (title: "Focus", subtitle: "开启 25 分钟专注会话", icon: "moon.stars.fill", color: AppTheme.lavender),
        (title: "Scan", subtitle: "快速扫描并存档文档", icon: "qrcode.viewfinder", color: AppTheme.primaryText)
    ]
    
    init() {
        loadTasks()
    }
    
    func loadTasks() {
        if let data = UserDefaults.standard.data(forKey: "tasks"),
           let decoded = try? JSONDecoder().decode([SchemaV1.TodoItem].self, from: data) {
            tasks = decoded
        } else {
            tasks = [
                SchemaV1.TodoItem(title: "完成 PersonalOS 开发", category: "Work", priority: 2),
                SchemaV1.TodoItem(title: "阅读技术文章", category: "Dev", priority: 1),
                SchemaV1.TodoItem(title: "健身打卡", category: "Life", priority: 1)
            ]
        }
    }
    
    func addTask(_ task: SchemaV1.TodoItem) {
        tasks.append(task)
        saveTasks()
    }
    
    func toggleTask(_ task: SchemaV1.TodoItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            saveTasks()
        }
    }
    
    func deleteTask(_ task: SchemaV1.TodoItem) {
        tasks.removeAll { $0.id == task.id }
        saveTasks()
    }
    
    private func saveTasks() {
        if let encoded = try? JSONEncoder().encode(tasks) {
            UserDefaults.standard.set(encoded, forKey: "tasks")
        }
    }
}
