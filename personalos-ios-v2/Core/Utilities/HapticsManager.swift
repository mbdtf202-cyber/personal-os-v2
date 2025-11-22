import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    private let lightGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let softGenerator = UIImpactFeedbackGenerator(style: .soft)
    private let rigidGenerator = UIImpactFeedbackGenerator(style: .rigid)
    private let selectionGenerator = UISelectionFeedbackGenerator()
    private let notificationGenerator = UINotificationFeedbackGenerator()
    
    private var isEnabled = true
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        lightGenerator.prepare()
        mediumGenerator.prepare()
        heavyGenerator.prepare()
        softGenerator.prepare()
        rigidGenerator.prepare()
        selectionGenerator.prepare()
        notificationGenerator.prepare()
    }
    
    // MARK: - Basic Haptics
    
    func light() {
        guard isEnabled else { return }
        lightGenerator.impactOccurred()
        lightGenerator.prepare()
    }
    
    func medium() {
        guard isEnabled else { return }
        mediumGenerator.impactOccurred()
        mediumGenerator.prepare()
    }
    
    func heavy() {
        guard isEnabled else { return }
        heavyGenerator.impactOccurred()
        heavyGenerator.prepare()
    }
    
    func soft() {
        guard isEnabled else { return }
        softGenerator.impactOccurred()
        softGenerator.prepare()
    }
    
    func rigid() {
        guard isEnabled else { return }
        rigidGenerator.impactOccurred()
        rigidGenerator.prepare()
    }
    
    func selection() {
        guard isEnabled else { return }
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare()
    }
    
    // MARK: - Notification Haptics
    
    func success() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare()
    }
    
    func warning() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.warning)
        notificationGenerator.prepare()
    }
    
    func error() {
        guard isEnabled else { return }
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare()
    }
    
    // MARK: - Contextual Haptics
    
    func taskCompleted() {
        success()
    }
    
    func taskDeleted() {
        medium()
    }
    
    func buttonTap() {
        light()
    }
    
    func cardSwipe() {
        soft()
    }
    
    func pullToRefresh() {
        medium()
    }
    
    func longPress() {
        rigid()
    }
    
    func toggle() {
        selection()
    }
    
    func scroll() {
        soft()
    }
    
    func dragStart() {
        medium()
    }
    
    func dragEnd() {
        light()
    }
    
    func modalPresent() {
        medium()
    }
    
    func modalDismiss() {
        light()
    }
    
    // MARK: - Custom Patterns
    
    func doubleLight() {
        guard isEnabled else { return }
        light()
        Task {
            try? await Task.sleep(nanoseconds: 100_000_000)
            light()
        }
    }
    
    func crescendo() {
        guard isEnabled else { return }
        Task {
            light()
            try? await Task.sleep(nanoseconds: 100_000_000)
            medium()
            try? await Task.sleep(nanoseconds: 100_000_000)
            heavy()
        }
    }
    
    func heartbeat() {
        guard isEnabled else { return }
        Task {
            medium()
            try? await Task.sleep(nanoseconds: 200_000_000)
            medium()
        }
    }
    
    // MARK: - Settings
    
    func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            prepareAll()
        }
    }
}
