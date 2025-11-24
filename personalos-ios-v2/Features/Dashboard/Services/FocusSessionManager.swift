import Foundation
import SwiftData
import UserNotifications

/// Manages focus session lifecycle with persistence and background support
@Observable
final class FocusSessionManager {
    private(set) var currentSession: FocusSession?
    private(set) var remainingTime: TimeInterval = 0
    private(set) var isRunning: Bool = false
    
    private var timer: Timer?
    private let modelContext: ModelContext
    private let notificationCenter = UNUserNotificationCenter.current()
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Start a new focus session
    func startSession(duration: TimeInterval, mode: String = "focus") async throws {
        // End any existing session
        if let existing = currentSession {
            try await endSession()
        }
        
        // Create new session
        let session = FocusSession(
            startTime: Date(),
            duration: duration,
            mode: mode,
            isActive: true
        )
        
        modelContext.insert(session)
        try modelContext.save()
        
        currentSession = session
        remainingTime = duration
        isRunning = true
        
        // Schedule notification
        await scheduleCompletionNotification(for: session)
        
        // Start timer
        startTimer()
        
        Logger.log("Focus session started: \(mode), duration: \(duration)s", category: Logger.general)
    }
    
    /// Pause the current session
    func pauseSession() async throws {
        guard let session = currentSession, isRunning else {
            throw FocusSessionError.noActiveSession
        }
        
        session.pausedAt = Date()
        session.elapsedTime += Date().timeIntervalSince(session.startTime)
        
        try modelContext.save()
        
        isRunning = false
        stopTimer()
        
        // Cancel notification
        await cancelNotifications()
        
        Logger.log("Focus session paused", category: Logger.general)
    }
    
    /// Resume the paused session
    func resumeSession() async throws {
        guard let session = currentSession, !isRunning else {
            throw FocusSessionError.noActiveSession
        }
        
        session.startTime = Date()
        session.pausedAt = nil
        
        try modelContext.save()
        
        isRunning = true
        startTimer()
        
        // Reschedule notification
        await scheduleCompletionNotification(for: session)
        
        Logger.log("Focus session resumed", category: Logger.general)
    }
    
    /// End the current session
    func endSession() async throws {
        guard let session = currentSession else {
            throw FocusSessionError.noActiveSession
        }
        
        session.completedAt = Date()
        session.isActive = false
        
        try modelContext.save()
        
        currentSession = nil
        remainingTime = 0
        isRunning = false
        stopTimer()
        
        // Cancel notification
        await cancelNotifications()
        
        Logger.log("Focus session ended", category: Logger.general)
    }
    
    /// Restore session after app restart
    func restoreSession() async {
        do {
            // Find active session
            let descriptor = FetchDescriptor<FocusSession>(
                predicate: #Predicate { $0.isActive && $0.completedAt == nil }
            )
            
            let sessions = try modelContext.fetch(descriptor)
            
            guard let session = sessions.first else {
                Logger.log("No active session to restore", category: Logger.general)
                return
            }
            
            currentSession = session
            
            // Calculate remaining time
            let elapsed = session.elapsedTime + (session.pausedAt == nil ? Date().timeIntervalSince(session.startTime) : 0)
            remainingTime = max(0, session.duration - elapsed)
            
            // Check if session should have completed
            if remainingTime <= 0 {
                try await completeSession()
            } else if session.pausedAt == nil {
                // Resume if not paused
                isRunning = true
                startTimer()
                Logger.log("Focus session restored: \(remainingTime)s remaining", category: Logger.general)
            } else {
                Logger.log("Focus session restored (paused): \(remainingTime)s remaining", category: Logger.general)
            }
            
        } catch {
            Logger.error("Failed to restore session: \(error)", category: Logger.general)
        }
    }
    
    // MARK: - Private Methods
    
    private func startTimer() {
        stopTimer()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let session = self.currentSession else { return }
            
            let elapsed = session.elapsedTime + Date().timeIntervalSince(session.startTime)
            self.remainingTime = max(0, session.duration - elapsed)
            
            if self.remainingTime <= 0 {
                Task {
                    try? await self.completeSession()
                }
            }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func completeSession() async throws {
        guard let session = currentSession else { return }
        
        session.completedAt = Date()
        session.isActive = false
        
        try modelContext.save()
        
        currentSession = nil
        remainingTime = 0
        isRunning = false
        stopTimer()
        
        // Deliver completion notification if app is in background
        await deliverCompletionNotification(for: session)
        
        Logger.log("Focus session completed: \(session.mode)", category: Logger.general)
    }
    
    // MARK: - Notifications
    
    private func scheduleCompletionNotification(for session: FocusSession) async {
        // Request authorization
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            guard granted else {
                Logger.warning("Notification permission not granted", category: Logger.general)
                return
            }
        } catch {
            Logger.error("Failed to request notification permission: \(error)", category: Logger.general)
            return
        }
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great job! Your \(session.mode) session is finished."
        content.sound = .default
        content.categoryIdentifier = "FOCUS_SESSION"
        
        // Schedule notification
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: session.remainingTime,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "focus_session_\(session.id.uuidString)",
            content: content,
            trigger: trigger
        )
        
        do {
            try await notificationCenter.add(request)
            Logger.log("Scheduled completion notification for session", category: Logger.general)
        } catch {
            Logger.error("Failed to schedule notification: \(error)", category: Logger.general)
        }
    }
    
    private func cancelNotifications() async {
        guard let session = currentSession else { return }
        
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: ["focus_session_\(session.id.uuidString)"]
        )
        
        Logger.log("Cancelled notifications for session", category: Logger.general)
    }
    
    private func deliverCompletionNotification(for session: FocusSession) async {
        let content = UNMutableNotificationContent()
        content.title = "Focus Session Complete!"
        content.body = "Great job! Your \(session.mode) session is finished."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "focus_complete_\(session.id.uuidString)",
            content: content,
            trigger: nil  // Deliver immediately
        )
        
        do {
            try await notificationCenter.add(request)
        } catch {
            Logger.error("Failed to deliver completion notification: \(error)", category: Logger.general)
        }
    }
}

/// Focus session errors
enum FocusSessionError: Error, LocalizedError {
    case noActiveSession
    case sessionAlreadyActive
    case invalidDuration
    
    var errorDescription: String? {
        switch self {
        case .noActiveSession:
            return "No active focus session"
        case .sessionAlreadyActive:
            return "A focus session is already active"
        case .invalidDuration:
            return "Invalid session duration"
        }
    }
}
