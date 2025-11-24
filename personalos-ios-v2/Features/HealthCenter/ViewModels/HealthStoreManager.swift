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
    
    // ✅ P2 Fix: Add authorization tracking
    var isAuthorized: Bool {
        return healthKitService.isAuthorized
    }
    
    var authorizationError: String? {
        return healthKitService.authorizationError
    }
    
    var isHealthKitAvailable: Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #else
        return true
        #endif
    }

    init() {
        // 构造函数保持纯净，不执行副作用
        // 数据加载由显式调用触发
    }
    
    func requestHealthKitAuthorization() async {
        do {
            try await healthKitService.requestAuthorization()
            healthKitService.authorizationError = nil
            await syncHealthData()
        } catch {
            // ✅ P2 Fix: Set authorization error message
            if let healthError = error as? HealthDataError {
                healthKitService.authorizationError = healthError.errorDescription
            } else {
                healthKitService.authorizationError = "Failed to authorize: \(error.localizedDescription)"
            }
            Logger.error("Failed to request HealthKit authorization: \(error)", category: Logger.health)
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
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let daySymbol = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
            
            // Fetch real sleep data for this date
            let startOfDay = calendar.startOfDay(for: date)
            guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { continue }
            let hours = await healthKitService.fetchSleepHours(from: startOfDay, to: endOfDay)
            
            history.append((daySymbol, hours))
        }
        
        sleepHistory = history
    }
}

