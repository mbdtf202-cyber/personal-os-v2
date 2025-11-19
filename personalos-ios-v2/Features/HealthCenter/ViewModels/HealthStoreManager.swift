import SwiftUI
import Observation

@MainActor
@Observable
class HealthStoreManager {
    private let storeKey = "habits"
    private let persistenceQueue = DispatchQueue(label: "app.habits.persistence", qos: .userInitiated)
    
    let healthKitService = HealthKitService()

    var steps: Int = 0
    var sleepHours: Double = 0.0
    var energyLevel: Double = 0.8
    var heartRate: Int = 0

    var sleepHistory: [(day: String, hours: Double)] = []

    var habits: [HabitItem] = []

    init() {
        Task {
            await loadHabits()
            await healthKitService.requestAuthorization()
            await syncHealthData()
        }
    }
    
    func syncHealthData() async {
        steps = healthKitService.todaySteps
        sleepHours = healthKitService.lastNightSleep
        heartRate = healthKitService.heartRate
        
        // Generate sleep history from last 7 days
        let calendar = Calendar.current
        let today = Date()
        sleepHistory = (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let daySymbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            let hours = Double.random(in: 6.0...9.0) // TODO: Fetch real data
            return (daySymbol, hours)
        }
    }

    func loadHabits() async {
        let storeKey = self.storeKey
        let decoded = await withCheckedContinuation { continuation in
            persistenceQueue.async {
                let data = UserDefaults.standard.data(forKey: storeKey)
                let habits = data.flatMap { try? JSONDecoder().decode([HabitItem].self, from: $0) }
                continuation.resume(returning: habits)
            }
        }

        habits = decoded ?? Self.defaultHabits
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
        let snapshot = habits
        let storeKey = self.storeKey
        persistenceQueue.async {
            guard let encoded = try? JSONEncoder().encode(snapshot) else { return }
            UserDefaults.standard.set(encoded, forKey: storeKey)
        }
    }

    private static let defaultHabits: [HabitItem] = [
        HabitItem(icon: "drop.fill", title: "Drink 2L Water", color: AppTheme.mistBlue),
        HabitItem(icon: "book.fill", title: "Read 30 mins", color: AppTheme.lavender),
        HabitItem(icon: "figure.mind.and.body", title: "Meditation", color: AppTheme.matcha),
        HabitItem(icon: "moon.stars.fill", title: "Sleep Early", color: AppTheme.primaryText)
    ]
}


