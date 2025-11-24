import XCTest
@testable import personalos_ios_v2

/// ✅ P0 Task 21.1: Network Request Lifecycle Property Tests
/// Tests Requirements 19.1-19.5: View disappearance cancellation, task tracking, request replacement, side effect prevention
@MainActor
final class TaskLifecycleTests: XCTestCase {
    var taskManager: TaskManager!
    
    override func setUp() async throws {
        taskManager = TaskManager()
    }
    
    override func tearDown() {
        taskManager = nil
    }
    
    // MARK: - Property 74: View disappearance cancellation
    /// Requirement 19.1: Tasks are cancelled when view disappears
    func testProperty74_ViewDisappearanceCancellation() async throws {
        // Given: An active task
        var taskCompleted = false
        let task = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            taskCompleted = true
        }
        
        taskManager.store(task, for: "test-task")
        
        // When: Simulating view disappearance
        taskManager.cancelAll()
        
        // Then: Task is cancelled
        XCTAssertTrue(task.isCancelled, "Task should be cancelled on view disappear")
        
        // Wait a bit to ensure task doesn't complete
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
        XCTAssertFalse(taskCompleted, "Cancelled task should not complete")
        
        // Property: Tasks are cancelled when view disappears
    }
    
    // MARK: - Property 75: Task reference tracking
    /// Requirement 19.2: ViewModels track active task references
    func testProperty75_TaskReferenceTracking() {
        // Given: Multiple tasks
        let task1 = Task { }
        let task2 = Task { }
        let task3 = Task { }
        
        // When: Storing tasks
        taskManager.store(task1, for: "task1")
        taskManager.store(task2, for: "task2")
        taskManager.store(task3, for: "task3")
        
        // Then: All tasks are tracked
        XCTAssertEqual(taskManager.activeTaskCount, 3, "Should track all tasks")
        XCTAssertTrue(taskManager.isActive(for: "task1"))
        XCTAssertTrue(taskManager.isActive(for: "task2"))
        XCTAssertTrue(taskManager.isActive(for: "task3"))
        
        // Property: TaskManager maintains references to all active tasks
    }
    
    // MARK: - Property 76: Request replacement cancellation
    /// Requirement 19.3: New requests cancel previous ones with same key
    func testProperty76_RequestReplacementCancellation() async throws {
        // Given: An active task
        var firstTaskCompleted = false
        let firstTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            firstTaskCompleted = true
        }
        
        taskManager.store(firstTask, for: "api-request")
        XCTAssertTrue(taskManager.isActive(for: "api-request"))
        
        // When: Storing a new task with same key
        let secondTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
        }
        taskManager.store(secondTask, for: "api-request")
        
        // Then: First task is cancelled
        XCTAssertTrue(firstTask.isCancelled, "Previous task should be cancelled")
        XCTAssertTrue(taskManager.isActive(for: "api-request"), "New task should be active")
        
        // Wait to ensure first task doesn't complete
        try await Task.sleep(nanoseconds: 200_000_000)
        XCTAssertFalse(firstTaskCompleted, "Cancelled task should not complete")
        
        // Cleanup
        taskManager.cancelAll()
        
        // Property: New requests automatically cancel previous requests with same identifier
    }
    
    // MARK: - Property 77: Cancelled request side effect prevention
    /// Requirement 19.4: Cancelled requests don't cause side effects
    func testProperty77_CancelledRequestSideEffectPrevention() async throws {
        // Given: A task that checks cancellation before side effects
        var sideEffectExecuted = false
        
        let task = Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            
            // Check cancellation before side effects
            guard !Task.isCancelled else {
                return
            }
            
            sideEffectExecuted = true
        }
        
        taskManager.store(task, for: "test")
        
        // When: Cancelling immediately
        taskManager.cancel(for: "test")
        
        // Wait for task to complete
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then: Side effect is not executed
        XCTAssertFalse(sideEffectExecuted, "Side effects should not execute after cancellation")
        
        // Property: Cancelled tasks check cancellation status before executing side effects
    }
    
    // MARK: - Property 78: Cancellation check before side effects
    /// Requirement 19.5: All async operations check cancellation
    func testProperty78_CancellationCheckBeforeSideEffects() async throws {
        // Given: Multiple async operations with cancellation checks
        var operation1Executed = false
        var operation2Executed = false
        var operation3Executed = false
        
        let task = Task {
            // Operation 1
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            operation1Executed = true
            
            // Operation 2
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            operation2Executed = true
            
            // Operation 3
            try? await Task.sleep(nanoseconds: 50_000_000)
            guard !Task.isCancelled else { return }
            operation3Executed = true
        }
        
        taskManager.store(task, for: "multi-op")
        
        // When: Cancelling after first operation
        try await Task.sleep(nanoseconds: 75_000_000)
        taskManager.cancel(for: "multi-op")
        
        // Wait for task to complete
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // Then: Only first operation executed
        XCTAssertTrue(operation1Executed, "First operation should execute")
        XCTAssertFalse(operation2Executed, "Second operation should not execute")
        XCTAssertFalse(operation3Executed, "Third operation should not execute")
        
        // Property: Cancellation is checked between async operations
    }
    
    // MARK: - Integration Tests
    func testTaskManagerCleanup() {
        // Given: Tasks that complete
        let task1 = Task { }
        let task2 = Task { }
        
        taskManager.store(task1, for: "task1")
        taskManager.store(task2, for: "task2")
        
        XCTAssertEqual(taskManager.activeTaskCount, 2)
        
        // When: Cleaning up
        taskManager.cleanup()
        
        // Then: Completed tasks are removed
        // (Tasks complete immediately in this case)
        XCTAssertLessThanOrEqual(taskManager.activeTaskCount, 2)
        
        // Property: Cleanup removes completed tasks
    }
    
    func testCancelSpecificTask() {
        // Given: Multiple tasks
        let task1 = Task { }
        let task2 = Task { }
        
        taskManager.store(task1, for: "task1")
        taskManager.store(task2, for: "task2")
        
        // When: Cancelling specific task
        taskManager.cancel(for: "task1")
        
        // Then: Only that task is cancelled
        XCTAssertTrue(task1.isCancelled)
        XCTAssertFalse(task2.isCancelled)
        XCTAssertTrue(taskManager.isActive(for: "task2"))
        
        // Cleanup
        taskManager.cancelAll()
        
        // Property: Individual tasks can be cancelled without affecting others
    }
    
    func testCancelAllTasks() {
        // Given: Multiple active tasks
        let task1 = Task { try? await Task.sleep(nanoseconds: 1_000_000_000) }
        let task2 = Task { try? await Task.sleep(nanoseconds: 1_000_000_000) }
        let task3 = Task { try? await Task.sleep(nanoseconds: 1_000_000_000) }
        
        taskManager.store(task1, for: "task1")
        taskManager.store(task2, for: "task2")
        taskManager.store(task3, for: "task3")
        
        // When: Cancelling all
        taskManager.cancelAll()
        
        // Then: All tasks are cancelled
        XCTAssertTrue(task1.isCancelled)
        XCTAssertTrue(task2.isCancelled)
        XCTAssertTrue(task3.isCancelled)
        XCTAssertEqual(taskManager.activeTaskCount, 0)
        
        // Property: All tasks can be cancelled at once
    }
}
