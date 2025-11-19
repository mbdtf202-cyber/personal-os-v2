import SwiftUI

struct ProgressRing: View {
    var progress: Double // 0.0 - 1.0
    var color: Color
    var icon: String
    var title: String
    var value: String
    var unit: String
    
    var body: some View {
        HStack(spacing: 16) {
            // 环形图表
            ZStack {
                // 背景环
                Circle()
                    .stroke(color.opacity(0.15), lineWidth: 8)
                
                // 进度环
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(duration: 1.0), value: progress)
                
                // 中心图标
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(color)
            }
            .frame(width: 56, height: 56)
            
            // 文本数据
            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(AppTheme.primaryText)
                    Text(unit)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                Text(title)
                    .font(.caption)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.6))
        .cornerRadius(20)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        ProgressRing(progress: 0.75, color: AppTheme.matcha, icon: "figure.walk", title: "Steps", value: "8,240", unit: "步")
    }
}
