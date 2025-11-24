import Foundation
import SwiftData

/// Focus session model for persistence
@Model
final class FocusSession {
    var id: UUID
    var startTime: Date
    var duration: TimeInterval
    var pausedAt: Date?
    var completedAt: Date?
    var isActive: Bool
    var mode: String  // "focus", "shortBreak", "longBreak"
    var elapsedTime: TimeInterval
    
    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        duration: TimeInterval,
        mode: String = "focus",
        isActive: Bool = true
    ) {
        self.id = id
        self.startTime = startTime
        self.duration = duration
        self.mode = mode
        self.isActive = isActive
        self.elapsedTime = 0
    }
    
    /// Calculate remaining time
    var remainingTime: TimeInterval {
        let elapsed = elapsedTime + (pausedAt == nil && isActive ? Date().timeIntervalSince(startTime) : 0)
        return max(0, duration - elapsed)
    }
    
    /// Check if session is completed
    var isCompleted: Bool {
        return completedAt != nil
    }
    
    /// Check if session is paused
    var isPaused: Bool {
        return pausedAt != nil && isActive
    }
}
