import Foundation

/// ✅ P0 Task 21: Task lifecycle manager for network requests
/// Requirement 19.1-19.5: Manage active tasks, cancel on view disappear, prevent side effects
@MainActor
class TaskManager {
    private var activeTasks: [String: Task<Void, Never>] = [:]
    
    /// Store a task with an identifier
    func store(_ task: Task<Void, Never>, for key: String) {
        // Cancel existing task with same key
        if let existingTask = activeTasks[key] {
            existingTask.cancel()
        }
        activeTasks[key] = task
    }
    
    /// Cancel a specific task
    func cancel(for key: String) {
        activeTasks[key]?.cancel()
        activeTasks.removeValue(forKey: key)
    }
    
    /// Cancel all active tasks
    func cancelAll() {
        for (_, task) in activeTasks {
            task.cancel()
        }
        activeTasks.removeAll()
    }
    
    /// Check if a task is active
    func isActive(for key: String) -> Bool {
        guard let task = activeTasks[key] else { return false }
        return !task.isCancelled
    }
    
    /// Get count of active tasks
    var activeTaskCount: Int {
        activeTasks.count
    }
    
    /// Clean up completed tasks
    func cleanup() {
        activeTasks = activeTasks.filter { !$0.value.isCancelled }
    }
}

/// Protocol for ViewModels that manage network requests
protocol TaskManaging {
    var taskManager: TaskManager { get }
    func cancelAllTasks()
}

extension TaskManaging {
    func cancelAllTasks() {
        taskManager.cancelAll()
    }
}
