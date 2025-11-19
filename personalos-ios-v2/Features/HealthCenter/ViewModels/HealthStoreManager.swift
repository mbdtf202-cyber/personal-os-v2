import SwiftUI
import Observation

@Observable
class HealthStoreManager {
    var steps: Int = 6540
    var sleepHours: Double = 7.2
    var energyLevel: Double = 0.8
    var heartRate: Int = 72
    
    var sleepHistory: [(day: String, hours: Double)] = [
        ("Mon", 6.5), ("Tue", 7.0), ("Wed", 8.2), ("Thu", 6.8),
        ("Fri", 7.5), ("Sat", 9.0), ("Sun", 7.2)
    ]
    
    var habits: [HabitItem] = []
    
    init() {
        loadHabits()
    }
    
    func loadHabits() {
        if let data = UserDefaults.standard.data(forKey: "habits"),
           let decoded = try? JSONDecoder().decode([HabitItem].self, from: data) {
            habits = decoded
        } else {
            habits = [
                HabitItem(icon: "drop.fill", title: "Drink 2L Water", color: AppTheme.mistBlue),
                HabitItem(icon: "book.fill", title: "Read 30 mins", color: AppTheme.lavender),
                HabitItem(icon: "figure.mind.and.body", title: "Meditation", color: AppTheme.matcha),
                HabitItem(icon: "moon.stars.fill", title: "Sleep Early", color: AppTheme.primaryText)
            ]
        }
    }
    
    func toggleHabit(id: UUID) {
        if let index = habits.firstIndex(where: { $0.id == id }) {
            habits[index].isCompleted.toggle()
            saveHabits()
        }
    }
    
    func addHabit(_ habit: HabitItem) {
        habits.append(habit)
        saveHabits()
    }
    
    private func saveHabits() {
        if let encoded = try? JSONEncoder().encode(habits) {
            UserDefaults.standard.set(encoded, forKey: "habits")
        }
    }
}


