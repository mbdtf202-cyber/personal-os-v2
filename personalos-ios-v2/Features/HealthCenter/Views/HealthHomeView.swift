import SwiftUI
import Charts

struct HealthHomeView: View {
    @State private var manager = HealthStoreManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        dateHeader
                        metricsGrid
                        sleepChartSection
                        MoodLogView(energyLevel: $manager.energyLevel)
                        HabitTrackerView(habits: $manager.habits)
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Health Center")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    // MARK: - Components
    
    private var dateHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(Date().formatted(date: .complete, time: .omitted))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                Text("Keep it up, Alex!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
            }
            Spacer()
            Circle()
                .fill(AppTheme.matcha)
                .frame(width: 40, height: 40)
                .overlay(Text("A").foregroundStyle(.white).bold())
        }
    }
    
    private var metricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
            MetricCard(title: "Steps", value: "\(manager.steps)", icon: "figure.walk", color: AppTheme.matcha)
            MetricCard(title: "Heart Rate", value: "\(manager.heartRate) bpm", icon: "heart.fill", color: AppTheme.coral)
        }
    }
    
    private var sleepChartSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "bed.double.fill")
                    .foregroundStyle(AppTheme.mistBlue)
                Text("Sleep Quality")
                    .font(.headline)
            }
            
            Chart {
                ForEach(manager.sleepHistory, id: \.day) { item in
                    BarMark(
                        x: .value("Day", item.day),
                        y: .value("Hours", item.hours)
                    )
                    .foregroundStyle(item.hours >= 7.0 ? AppTheme.mistBlue : AppTheme.coral.opacity(0.7))
                    .cornerRadius(6)
                    
                    RuleMark(y: .value("Goal", 8.0))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [5]))
                        .foregroundStyle(AppTheme.secondaryText.opacity(0.5))
                }
            }
            .frame(height: 180)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
        }
        .glassCard()
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: AppTheme.shadow, radius: 8, y: 4)
    }
}

#Preview {
    HealthHomeView()
}
