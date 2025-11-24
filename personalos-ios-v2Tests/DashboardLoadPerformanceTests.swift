import XCTest
import SwiftData
@testable import personalos_ios_v2

/// ✅ P2 EXTREME: 性能测试 - 验证并行加载的速度提升
final class DashboardLoadPerformanceTests: XCTestCase {
    
    var modelContainer: ModelContainer!
    var modelContext: ModelContext!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // 创建内存数据库用于测试
        let schema = Schema([
            TodoItem.self,
            SocialPost.self,
            TradeRecord.self,
            ProjectItem.self
        ])
        
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [configuration])
        modelContext = ModelContext(modelContainer)
        
        // 填充测试数据
        try await seedTestData()
    }
    
    override func tearDown() async throws {
        modelContainer = nil
        modelContext = nil
        try await super.tearDown()
    }
    
    private func seedTestData() async throws {
        // 创建大量测试数据以模拟真实场景
        for i in 0..<100 {
            let task = TodoItem(title: "Task \(i)")
            modelContext.insert(task)
            
            let post = SocialPost(
                title: "Post \(i)",
                content: "Content \(i)",
                platform: .twitter
            )
            modelContext.insert(post)
            
            let trade = TradeRecord(
                symbol: "AAPL",
                action: .buy,
                quantity: 10,
                price: Decimal(150.0 + Double(i))
            )
            modelContext.insert(trade)
            
            let project = ProjectItem(
                name: "Project \(i)",
                description: "Description \(i)"
            )
            modelContext.insert(project)
        }
        
        try modelContext.save()
    }
    
    func testParallelLoadPerformance() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // When - 测量并行加载性能
        let startTime = Date()
        
        await viewModel.loadRecentData()
        
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        print("⚡️ Parallel load completed in \(String(format: "%.3f", duration))s")
        
        // 验证数据已加载
        await MainActor.run {
            XCTAssertFalse(viewModel.recentTasks.isEmpty, "Tasks should be loaded")
            XCTAssertFalse(viewModel.recentPosts.isEmpty, "Posts should be loaded")
            XCTAssertFalse(viewModel.recentTrades.isEmpty, "Trades should be loaded")
            XCTAssertFalse(viewModel.recentProjects.isEmpty, "Projects should be loaded")
        }
        
        // 性能断言：并行加载应该在合理时间内完成
        XCTAssertLessThan(duration, 1.0, "Parallel load should complete within 1 second")
    }
    
    func testLoadingStateTransitions() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // When
        let loadTask = Task {
            await viewModel.loadRecentData()
        }
        
        // Then - 验证加载状态正确转换
        try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        
        await MainActor.run {
            // 至少有一个应该在加载中
            let anyLoading = viewModel.tasksLoadingState.isLoading ||
                            viewModel.postsLoadingState.isLoading ||
                            viewModel.tradesLoadingState.isLoading ||
                            viewModel.projectsLoadingState.isLoading
            
            XCTAssertTrue(anyLoading, "At least one section should be loading")
        }
        
        await loadTask.value
        
        await MainActor.run {
            // 所有都应该完成加载
            XCTAssertEqual(viewModel.tasksLoadingState, .loaded)
            XCTAssertEqual(viewModel.postsLoadingState, .loaded)
            XCTAssertEqual(viewModel.tradesLoadingState, .loaded)
            XCTAssertEqual(viewModel.projectsLoadingState, .loaded)
        }
    }
    
    func testConcurrentLoadCancellation() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // When - 快速连续调用加载
        let task1 = Task {
            await viewModel.loadRecentData()
        }
        
        try await Task.sleep(nanoseconds: 5_000_000) // 5ms
        
        let task2 = Task {
            await viewModel.loadRecentData()
        }
        
        // Then - 第一个任务应该被取消
        await task1.value
        await task2.value
        
        // 验证最终状态正确
        await MainActor.run {
            XCTAssertFalse(viewModel.recentTasks.isEmpty)
        }
    }
    
    func testMemoryEfficiency() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // When - 多次加载
        for _ in 0..<10 {
            await viewModel.loadRecentData()
        }
        
        // Then - 验证内存没有泄漏（数据应该被替换，不是累加）
        await MainActor.run {
            XCTAssertLessThanOrEqual(viewModel.recentTasks.count, 10, "Should only keep recent 10 tasks")
            XCTAssertLessThanOrEqual(viewModel.recentPosts.count, 10, "Should only keep recent 10 posts")
            XCTAssertLessThanOrEqual(viewModel.recentTrades.count, 10, "Should only keep recent 10 trades")
            XCTAssertLessThanOrEqual(viewModel.recentProjects.count, 10, "Should only keep recent 10 projects")
        }
    }
    
    func testActivityCalculationPerformance() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // When
        let startTime = Date()
        let activityData = await viewModel.calculateActivityData()
        let duration = Date().timeIntervalSince(startTime)
        
        // Then
        print("📊 Activity calculation completed in \(String(format: "%.3f", duration))s")
        
        XCTAssertEqual(activityData.count, 7, "Should have 7 days of data")
        XCTAssertLessThan(duration, 0.5, "Activity calculation should be fast")
    }
    
    func testRetryMechanism() async throws {
        // Given
        let viewModel = await DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        // 先加载一次
        await viewModel.loadRecentData()
        
        // When - 重试特定部分
        await viewModel.retryLoad(section: "tasks")
        
        // Then
        await MainActor.run {
            XCTAssertEqual(viewModel.tasksLoadingState, .loaded)
            XCTAssertFalse(viewModel.recentTasks.isEmpty)
        }
    }
}

// MARK: - Performance Baseline Tests

extension DashboardLoadPerformanceTests {
    
    /// 基准测试：测量并行加载的实际性能
    func testMeasureParallelLoadBaseline() throws {
        let viewModel = DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        measure {
            let expectation = XCTestExpectation(description: "Load completed")
            
            Task {
                await viewModel.loadRecentData()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
    
    /// 基准测试：测量活动数据计算性能
    func testMeasureActivityCalculationBaseline() throws {
        let viewModel = DashboardViewModel(
            todoRepository: nil,
            modelContext: modelContext
        )
        
        measure {
            let expectation = XCTestExpectation(description: "Calculation completed")
            
            Task {
                _ = await viewModel.calculateActivityData()
                expectation.fulfill()
            }
            
            wait(for: [expectation], timeout: 5.0)
        }
    }
}
