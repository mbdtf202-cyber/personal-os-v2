import Foundation
import SwiftData

@Model
final class HealthLog {
    var id: UUID
    var date: Date
    var sleepHours: Double
    var moodScore: Int
    var steps: Int
    var energyLevel: Int

    init(id: UUID = UUID(), date: Date = .now, sleepHours: Double = 0, moodScore: Int = 5, steps: Int = 0, energyLevel: Int = 50) {
        self.id = id
        self.date = date
        self.sleepHours = sleepHours
        self.moodScore = moodScore
        self.steps = steps
        self.energyLevel = energyLevel
    }
}
