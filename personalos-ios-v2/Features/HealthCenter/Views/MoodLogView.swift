import SwiftUI
import Combine

struct MoodLogView: View {
    @Binding var energyLevel: Double // 0.0 - 1.0
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bolt.heart.fill")
                    .foregroundStyle(AppTheme.almond)
                Text("Energy & Mood")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            
            VStack(spacing: 20) {
                // 动态表情反馈
                Image(systemName: getMoodIcon(level: energyLevel))
                    .font(.system(size: 40))
                    .foregroundStyle(getMoodColor(level: energyLevel))
                    .symbolEffect(.bounce, value: energyLevel)
                    .contentTransition(.symbolEffect(.replace))
                
                // 自定义滑块
                Slider(value: $energyLevel, in: 0...1)
                    .tint(getMoodColor(level: energyLevel))
            }
            .padding(.vertical, 10)
            
            HStack {
                Text("Exhausted")
                Spacer()
                Text("Energetic")
            }
            .font(.caption)
            .foregroundStyle(AppTheme.secondaryText)
        }
        .glassCard()
    }
    
    func getMoodIcon(level: Double) -> String {
        switch level {
        case 0.0..<0.3: return "cloud.rain.fill"
        case 0.3..<0.7: return "cloud.sun.fill"
        default: return "sun.max.fill"
        }
    }
    
    func getMoodColor(level: Double) -> Color {
        switch level {
        case 0.0..<0.3: return AppTheme.secondaryText
        case 0.3..<0.7: return AppTheme.mistBlue
        default: return AppTheme.almond
        }
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        MoodLogView(energyLevel: .constant(0.8)).padding()
    }
}
