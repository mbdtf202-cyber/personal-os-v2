import SwiftUI
import Observation

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
}

