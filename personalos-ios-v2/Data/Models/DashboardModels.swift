import Foundation

// MARK: - 仪表盘相关模型 (使用 Codable 而不是 @Model)

struct DailyOverview: Identifiable, Codable {
    var id: String
    var date: Date
    var todayTasks: Int = 0
    var completedTasks: Int = 0
    var healthCheckIn: Bool = false
    var mood: String = ""
    
    init(date: Date = Date()) {
        self.id = UUID().uuidString
        self.date = date
    }
}

struct HealthCheckIn: Identifiable, Codable {
    var id: String
    var date: Date
    var sleepHours: Double = 0
    var exerciseMinutes: Int = 0
    var moodScore: Int = 5
    var energyLevel: Int = 5
    var stressLevel: Int = 5
    
    init(date: Date = Date()) {
        self.id = UUID().uuidString
        self.date = date
    }
}

import SwiftUI
