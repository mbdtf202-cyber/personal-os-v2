import XCTest
import SwiftData
@testable import personalos_ios_v2

@MainActor
final class DashboardViewModelTests: XCTestCase {
    var modelContext: ModelContext!
    var repository: TodoRepository!
    var viewModel: DashboardViewModel!
    
    override func setUp() async throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: TodoItem.self, SocialPost.self, TradeRecord.self,
            configurations: config
        )
        modelContext = ModelContext(container)
        repository = TodoRepository(modelContext: modelContext)
        viewModel = DashboardViewModel(todoRepository: repository, modelContext: modelContext)
    }
    
    override func tearDown() {
        modelContext = nil
        repository = nil
        viewModel = nil
    }
    
    // MARK: - greeting Tests
    
    func testGreeting_Morning() {
        // 无法直接测试时间依赖的方法，但可以验证返回值类型
        let greeting = viewModel.greeting
        XCTAssertFalse(greeting.isEmpty)
        XCTAssertTrue(["Good Morning", "Good Afternoon", "Good Evening", "Good Night"].contains(greeting))
    }
    
    // MARK: - dailyBriefing Tests
    
    func testDailyBriefing_NoPendingTasks() {
        let tasks = [
            TodoItem(title: "Task 1", isCompleted: true),
            TodoItem(title: "Task 2", isCompleted: true)
        ]
        
        let briefing = viewModel.dailyBriefing(tasks: tasks, steps: 5000)
        XCTAssertTrue(briefing.contains("all caught up"))
        XCTAssertTrue(briefing.contains("5000"))
    }
    
    func testDailyBriefing_WithPendingTasks() {
        let tasks = [
            TodoItem(title: "Task 1", isCompleted: false),
            TodoItem(title: "Task 2", isCompleted: true),
            TodoItem(title: "Task 3", isCompleted: false)
        ]
        
        let briefing = viewModel.dailyBriefing(tasks: tasks, steps: 8000)
        XCTAssertTrue(briefing.contains("2 tasks pending"))
        XCTAssertTrue(briefing.contains("8000"))
    }
    
    // MARK: - addTask Tests
    
    func testAddTask_Success() async {
        await viewModel.addTask(title: "New Task")
        
        let tasks = try? await repository.fetch()
        XCTAssertEqual(tasks?.count, 1)
        XCTAssertEqual(tasks?.first?.title, "New Task")
        XCTAssertFalse(tasks?.first?.isCompleted ?? true)
    }
    
    // MARK: - toggleTask Tests
    
    func testToggleTask() async {
        let task = TodoItem(title: "Test Task", isCompleted: false)
        try? await repository.save(task)
        
        await viewModel.toggleTask(task)
        
        XCTAssertTrue(task.isCompleted)
        
        await viewModel.toggleTask(task)
        
        XCTAssertFalse(task.isCompleted)
    }
    
    // MARK: - deleteTask Tests
    
    func testDeleteTask() async {
        let task = TodoItem(title: "Test Task")
        try? await repository.save(task)
        
        await viewModel.deleteTask(task)
        
        let tasks = try? await repository.fetch()
        XCTAssertEqual(tasks?.count, 0)
    }
    
    // MARK: - loadRecentData Tests
    
    func testLoadRecentData_LimitTo10() async {
        // 创建 15 个任务
        for i in 1...15 {
            let task = TodoItem(title: "Task \(i)")
            try? await repository.save(task)
        }
        
        await viewModel.loadRecentData()
        
        XCTAssertEqual(viewModel.recentTasks.count, 10)
    }
    
    func testLoadRecentData_LessThan10() async {
        // 创建 5 个任务
        for i in 1...5 {
            let task = TodoItem(title: "Task \(i)")
            try? await repository.save(task)
        }
        
        await viewModel.loadRecentData()
        
        XCTAssertEqual(viewModel.recentTasks.count, 5)
    }
}
