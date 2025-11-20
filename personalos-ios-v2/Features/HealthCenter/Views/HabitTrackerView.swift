import SwiftUI
import Combine

struct HabitTrackerView: View {
    var habits: [HabitItem]
    var onToggle: (HabitItem) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Daily Habits")
                .font(.headline)
                .foregroundStyle(AppTheme.primaryText)

            LazyVStack(spacing: 12) {
                ForEach(habits) { habit in
                    HStack(spacing: 16) {
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
                        
                        Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { onToggle(habit) } }) {
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
        HabitTrackerView(
            habits: [
                HabitItem(title: "Drink 2L Water", icon: "drop.fill"),
                HabitItem(title: "Read 30 mins", icon: "book.fill")
            ],
            onToggle: { _ in }
        )
        .padding()
    }
}
