import SwiftUI

struct HabitTrackerView: View {
    @Binding var habits: [HabitItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Habits")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)
            
            VStack(spacing: 12) {
                ForEach($habits) { $habit in
                    HStack(spacing: 16) {
                        // 图标背景
                        ZStack {
                            Circle()
                                .fill(habit.color.opacity(0.15))
                                .frame(width: 40, height: 40)
                            Image(systemName: habit.icon)
                                .foregroundStyle(habit.color)
                        }
                        
                        Text(habit.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(AppTheme.primaryText)
                            .strikethrough(habit.isCompleted)
                            .opacity(habit.isCompleted ? 0.6 : 1.0)
                        
                        Spacer()
                        
                        // 打卡按钮
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                habit.isCompleted.toggle()
                            }
                        }) {
                            Image(systemName: habit.isCompleted ? "checkmark.circle.fill" : "circle")
                                .font(.title2)
                                .foregroundStyle(habit.isCompleted ? AppTheme.matcha : AppTheme.secondaryText.opacity(0.5))
                        }
                    }
                    .padding(12)
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(16)
                }
            }
        }
        .glassCard()
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        HabitTrackerView(habits: .constant([
            HabitItem(icon: "drop.fill", title: "Drink 2L Water", color: AppTheme.mistBlue),
            HabitItem(icon: "book.fill", title: "Read 30 mins", color: AppTheme.lavender)
        ]))
        .padding()
    }
}
