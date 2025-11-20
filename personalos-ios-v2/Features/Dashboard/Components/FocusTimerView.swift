import SwiftUI

struct FocusTimerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var timeRemaining: Int = 25 * 60 // 25 minutes in seconds
    @State private var isRunning: Bool = false
    @State private var timer: Timer?
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                HStack {
                    Spacer()
                    Button {
                        stopTimer()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding(.horizontal)
                
                VStack(spacing: 20) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(AppTheme.lavender)
                    
                    Text("Focus Session")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text(timeString)
                        .font(.system(size: 72, weight: .thin, design: .rounded))
                        .monospacedDigit()
                    
                    HStack(spacing: 20) {
                        Button {
                            if isRunning {
                                pauseTimer()
                            } else {
                                startTimer()
                            }
                        } label: {
                            Label(isRunning ? "Pause" : "Start", systemImage: isRunning ? "pause.fill" : "play.fill")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 120, height: 50)
                                .background(AppTheme.lavender)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        
                        Button {
                            resetTimer()
                        } label: {
                            Label("Reset", systemImage: "arrow.counterclockwise")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .frame(width: 120, height: 50)
                                .background(Color.gray.opacity(0.3))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .padding(40)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                
                Spacer()
            }
            .padding()
        }
    }
    
    private var timeString: String {
        let minutes = timeRemaining / 60
        let seconds = timeRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func startTimer() {
        isRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                stopTimer()
                HapticsManager.shared.success()
            }
        }
    }
    
    private func pauseTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        isRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func resetTimer() {
        stopTimer()
        timeRemaining = 25 * 60
    }
}
