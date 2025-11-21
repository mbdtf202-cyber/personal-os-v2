import SwiftUI
import Charts

struct EquityChart: View {
    let equityCurve: [EquityPoint]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Equity Curve (7D)")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            if equityCurve.isEmpty {
                Text("Log trades to view your equity curve.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.secondaryText)
            } else {
                Chart {
                    ForEach(equityCurve) { point in
                        LineMark(
                            x: .value("Day", point.day),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(AppTheme.almond)
                        .symbol(Circle())

                        AreaMark(
                            x: .value("Day", point.day),
                            y: .value("Value", point.value)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.almond.opacity(0.3), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel()
                            .font(.caption2)
                    }
                }
            }
        }
        .padding(16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(20)
    }
}
