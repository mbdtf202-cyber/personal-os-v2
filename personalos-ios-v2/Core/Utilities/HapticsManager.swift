import UIKit

@MainActor
final class HapticsManager {
    static let shared = HapticsManager()
    
    private let light = UIImpactFeedbackGenerator(style: .light)
    private let medium = UIImpactFeedbackGenerator(style: .medium)
    private let heavy = UIImpactFeedbackGenerator(style: .heavy)
    private let soft = UIImpactFeedbackGenerator(style: .soft)
    private let rigid = UIImpactFeedbackGenerator(style: .rigid)
    private let selection = UISelectionFeedbackGenerator()
    private let notification = UINotificationFeedbackGenerator()
    
    private var isEnabled = true
    
    private init() {
        prepareAll()
    }
    
    private func prepareAll() {
        light.prepare()
        medium.prepare()
        heavy.prepare()
        soft.prepare()
        rigid.prepare()
        selection.prepare()
        notification.prepare()
    }
    
    // MARK: - Basic Haptics
    
    func light() {
        guard isEnabled else { return }
        light.impactOccurred()
        light.prepare()
    }
    
    func medium() {
        guard isEnabled else { return }
        medium.impactOccurred()
        medium.prepare()
    }
    
    func heavy() {
        guard isEnabled else { return }
        heavy.impactOccurred()
        heavy.prepare()
    }
    
    func soft() {
        guard isEnabled else { return }
        soft.impactOccurred()
        soft.prepare()
    }
    
    func rigid() {
        guard isEnabled else { return }
        rigid.impactOccurred()
        rigid.prepare()
    }
    
    func selection() {
        guard isEnabled else { return }
        selection.selectionChanged()
        selection.prepare()
    }
    
    // MARK: - Notification Haptics
    
    func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
        notification.prepare()
    }
    
    func warning() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
        notification.prepare()
    }
    
    func error() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
        notification.prepare()
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
