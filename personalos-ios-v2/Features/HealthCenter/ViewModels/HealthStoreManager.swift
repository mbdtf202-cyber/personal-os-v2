import SwiftUI
import Observation
import Combine

@MainActor
@Observable
class HealthStoreManager {
    let healthKitService = HealthKitService()

    var steps: Int = 0
    var sleepHours: Double = 0.0
    var energyLevel: Double = 0.8
    var heartRate: Int = 0

    var sleepHistory: [(day: String, hours: Double)] = []

    init() {
        Task {
            await healthKitService.requestAuthorization()
            await syncHealthData()
        }
    }
    
    func syncHealthData() async {
        steps = healthKitService.todaySteps
        sleepHours = healthKitService.lastNightSleep
        heartRate = healthKitService.heartRate
        
        // Fetch real sleep history from last 7 days
        await fetchSleepHistory()
    }
    
    private func fetchSleepHistory() async {
        let calendar = Calendar.current
        let today = Date()
        var history: [(day: String, hours: Double)] = []
        
        for offset in (0..<7).reversed() {
            let date = calendar.date(byAdding: .day, value: -offset, to: today)!
            let daySymbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            // Fetch real sleep data for this date
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let hours = await healthKitService.fetchSleepHours(from: startOfDay, to: endOfDay)
            
            history.append((daySymbol, hours))
        }
        
        sleepHistory = history
    }
}

