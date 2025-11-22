import SwiftUI
import SwiftData

enum TimerMode: String, CaseIterable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"
    
    var duration: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
    
    var icon: String {
        switch self {
        case .focus: return "brain.head.profile"
        case .shortBreak: return "cup.and.saucer.fill"
        case .longBreak: return "bed.double.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .focus: return AppTheme.lavender
        case .shortBreak: return AppTheme.matcha
        case .longBreak: return AppTheme.mistBlue
        }
    }
}

struct FocusTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appDependency) private var appDependency
    @State private var timeRemaining: Int = 25 * 60
    @State private var totalTime: Int = 25 * 60
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    @State private var currentMode: TimerMode = .focus
    @State private var completedSessions: Int = 0
    @State private var showSettings: Bool = false
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Header
                HStack {
                    Button {
                        showSettings.toggle()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    // Session Counter
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(AppTheme.matcha)
                        Text("\(completedSessions)")
                            .font(.headline)
                            .foregroundStyle(.white)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    Spacer()
                    
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                
                // Mode Selector
                HStack(spacing: 12) {
                    ForEach(TimerMode.allCases, id: \.self) { mode in
                        Button {
                            switchMode(to: mode)
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: mode.icon)
                                    .font(.title3)
                                Text(mode.rawValue)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .foregroundStyle(currentMode == mode ? .white : .white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(currentMode == mode ? mode.color : Color.white.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .disabled(isRunning)
                    }
                }
                .padding(.horizontal)
                
                // Timer Display
                VStack(spacing: 20) {
                    Image(systemName: currentMode.icon)
                        .font(.system(size: 60))
                        .foregroundStyle(currentMode.color)
                    
                    Text(currentMode.rawValue)
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    
                    // Progress Ring
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.1), lineWidth: 12)
                            .frame(width: 240, height: 240)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(currentMode.color, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 240, height: 240)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.5), value: progress)
                        
                        VStack(spacing: 8) {
                            Text(timeString)
                                .font(.system(size: 56, weight: .thin, design: .rounded))
                                .monospacedDigit()
                                .foregroundStyle(.white)
                            
                            if isRunning {
                                Text("Stay focused...")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    
                    // Controls
                    HStack(spacing: 20) {
                        Button {
                            if isRunning {
                                pauseTimer()
                            } else {
                                startTimer()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: isRunning ? "pause.fill" : "play.fill")
                                Text(isRunning ? "Pause" : "Start")
                            }
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 140, height: 54)
                            .background(currentMode.color)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: currentMode.color.opacity(0.3), radius: 8, y: 4)
                        }
                        
                        Button {
                            resetTimer()
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 54, height: 54)
                                .background(Color.white.opacity(0.2))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                Spacer()
            }
            .padding()
            .sheet(isPresented: $showSettings) {
                TimerSettingsView(
                    focusDuration: Binding(
                        get: { TimerMode.focus.duration / 60 },
                        set: { _ in }
                    )
                )
            }
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private var progress: CGFloat {
        guard totalTime > 0 else { return 0 }
        return CGFloat(totalTime - timeRemaining) / CGFloat(totalTime)
    }
    
    private func switchMode(to mode: TimerMode) {
        guard !isRunning else { return }
        currentMode = mode
        totalTime = mode.duration
        timeRemaining = mode.duration
        HapticsManager.shared.light()
    }
    
    private func startTimer() {
        isRunning = true
        HapticsManager.shared.medium()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                completeSession()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        HapticsManager.shared.light()
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = totalTime
        HapticsManager.shared.light()
    }
    
    private func completeSession() {
        stopTimer()
        HapticsManager.shared.success()
        
        if currentMode == .focus {
            completedSessions += 1
            saveFocusSession()
            
            // Auto-switch to break
            if completedSessions % 4 == 0 {
                switchMode(to: .longBreak)
            } else {
                switchMode(to: .shortBreak)
            }
        } else {
            // After break, switch back to focus
            switchMode(to: .focus)
        }
    }
    
    private func saveFocusSession() {
        let session = HabitItem(
            title: "Focus Session Completed",
            icon: "brain.head.profile",
            isCompleted: true
        )
        Task {
            do {
                try await appDependency?.repositories.habit.save(session)
                Logger.log("Focus session completed: \(currentMode.rawValue)", category: Logger.general)
            } catch {
                ErrorHandler.shared.handle(error, context: "FocusTimerView.completeFocusSession")
            }
        }
    }
}

// MARK: - Timer Settings View
struct TimerSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var focusDuration: Int
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Timer Durations") {
                    Stepper("Focus: \(focusDuration) min", value: $focusDuration, in: 15...60, step: 5)
                    Text("Short Break: 5 min")
                        .foregroundStyle(AppTheme.secondaryText)
                    Text("Long Break: 15 min")
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Section("Pomodoro Technique") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("How it works:")
                            .font(.headline)
                        Text("1. Work for 25 minutes")
                        Text("2. Take a 5-minute break")
                        Text("3. After 4 sessions, take a 15-minute break")
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .navigationTitle("Timer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
