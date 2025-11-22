import Foundation
import SwiftData

/// 数据初始化引导器
/// ✅ 将数据种子逻辑从 View 层移出
@MainActor
final class DataBootstrapper {
    static let shared = DataBootstrapper()
    
    private var hasBootstrapped = false
    
    private init() {}
    
    func bootstrap(dependency: AppDependency) async {
        guard !hasBootstrapped else { return }
        
        Logger.log("🚀 Bootstrapping application data...", category: Logger.general)
        
        await seedDefaultTasksIfNeeded(dependency: dependency)
        await seedDefaultHabitsIfNeeded(dependency: dependency)
        
        hasBootstrapped = true
        Logger.log("✅ Data bootstrap complete", category: Logger.general)
    }
    
    private func seedDefaultTasksIfNeeded(dependency: AppDependency) async {
        do {
            let existingTasks = try await dependency.repositories.todo.fetch()
            guard existingTasks.isEmpty else {
                Logger.log("Tasks already exist, skipping seed", category: Logger.general)
                return
            }
            
            let defaultTasks = [
                TodoItem(title: "Welcome to PersonalOS", category: "Getting Started", priority: 1),
                TodoItem(title: "Explore the Dashboard", category: "Getting Started", priority: 1),
                TodoItem(title: "Set up your first goal", category: "Life", priority: 2)
            ]
            
            for task in defaultTasks {
                try await dependency.repositories.todo.save(task)
            }
            
            Logger.log("✅ Seeded \(defaultTasks.count) default tasks", category: Logger.general)
        } catch {
            Logger.error("Failed to seed tasks: \(error)", category: Logger.general)
        }
    }
    
    private func seedDefaultHabitsIfNeeded(dependency: AppDependency) async {
        do {
            let existingHabits = try await dependency.repositories.habit.fetch()
            guard existingHabits.isEmpty else {
                Logger.log("Habits already exist, skipping seed", category: Logger.general)
                return
            }
            
            let defaultHabits = [
                HabitItem(title: "Morning Exercise", icon: "figure.walk", isCompleted: false, streak: 0),
                HabitItem(title: "Read 30 Minutes", icon: "book.fill", isCompleted: false, streak: 0),
                HabitItem(title: "Meditation", icon: "brain.head.profile", isCompleted: false, streak: 0)
            ]
            
            for habit in defaultHabits {
                try await dependency.repositories.habit.save(habit)
            }
            
            Logger.log("✅ Seeded \(defaultHabits.count) default habits", category: Logger.general)
        } catch {
            Logger.error("Failed to seed habits: \(error)", category: Logger.general)
        }
    }
    
    func reset() {
        hasBootstrapped = false
    }
}
