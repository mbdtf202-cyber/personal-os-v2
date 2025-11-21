import SwiftUI
import Combine
import SwiftData
import Charts

struct HealthHomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \HabitItem.title) private var habits: [HabitItem]
    @Environment(HealthStoreManager.self) private var manager
    
    var body: some View {
        @Bindable var bindableManager = manager
        
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        dateHeader
                        metricsGrid
                        sleepChartSection
                        MoodLogView(energyLevel: $bindableManager.energyLevel)
                        HabitTrackerView(habits: habits, onToggle: toggleHabit)
                        Spacer(minLength: 100)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Health Center")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear(perform: seedHabitsIfNeeded)
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
        VStack(spacing: 16) {
            if manager.healthKitService.authorizationDenied {
                VStack(spacing: 12) {
                    Image(systemName: "heart.slash")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.coral)
                    Text("Health Access Denied")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryText)
                    Text("Enable Health permissions in Settings to track your health data")
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .multilineTextAlignment(.center)
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(AppTheme.mistBlue)
                    .cornerRadius(12)
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: AppTheme.shadow, radius: 8, y: 4)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    MetricCard(title: "Steps", value: "\(manager.steps)", icon: "figure.walk", color: AppTheme.matcha)
                    MetricCard(title: "Heart Rate", value: "\(manager.heartRate) bpm", icon: "heart.fill", color: AppTheme.coral)
                }
            }
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

    private func toggleHabit(_ habit: HabitItem) {
        habit.isCompleted.toggle()
        Task {
            try? await appDependency?.repositories.habit.save(habit)
        }
    }

    private func seedHabitsIfNeeded() {
        guard habits.isEmpty else { return }
        Task {
            for habit in HabitItem.defaultHabits {
                try? await appDependency?.repositories.habit.save(habit)
            }
        }
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
        .modelContainer(for: HabitItem.self, inMemory: true)
}
