import SwiftUI
import Charts

struct ActivityHeatmap: View {
    let data: [(day: String, value: Double)]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "flame.fill")
                    .foregroundStyle(AppTheme.coral)
                Text("Productivity Trend")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
            }
            
            Chart {
                ForEach(data, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Activity", item.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.mistBlue, AppTheme.lavender],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .cornerRadius(6)
                }
            }
            .frame(height: 160)
            .chartXAxis {
                AxisMarks(position: .bottom) { _ in
                    AxisValueLabel()
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            .chartYAxis(.hidden)
        }
        .glassCard()
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        ActivityHeatmap(data: [
            ("Mon", 45), ("Tue", 80), ("Wed", 30), ("Thu", 65),
            ("Fri", 90), ("Sat", 50), ("Sun", 75)
        ]).padding()
    }
}
