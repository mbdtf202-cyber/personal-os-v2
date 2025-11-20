import SwiftUI

struct ContentCalendarView: View {
    let days: [Date] = (0..<7).map { Date().addingTimeInterval(Double($0) * 86400) }
    var posts: [SocialPost]
    @Binding var selectedDate: Date?
    
    init(posts: [SocialPost], selectedDate: Binding<Date?> = .constant(nil)) {
        self.posts = posts
        self._selectedDate = selectedDate
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .foregroundStyle(AppTheme.almond)
                Text("Posting Schedule")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryText)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(days, id: \.self) { date in
                        Button(action: {
                            if let selected = selectedDate, Calendar.current.isDate(selected, inSameDayAs: date) {
                                selectedDate = nil // Deselect if clicking same date
                            } else {
                                selectedDate = date
                            }
                            HapticsManager.shared.light()
                        }) {
                            VStack(spacing: 8) {
                                Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                    .font(.caption2)
                                    .textCase(.uppercase)
                                    .foregroundStyle(AppTheme.secondaryText)
                                Text(date.formatted(.dateTime.day()))
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(isSelected(date) ? .white : (isToday(date) ? AppTheme.primaryText : AppTheme.secondaryText))
                                
                                // Dots for posts
                                HStack(spacing: 2) {
                                    let dayPosts = posts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                                    ForEach(dayPosts.prefix(3)) { post in
                                        Circle()
                                            .fill(isSelected(date) ? .white : post.platform.color)
                                            .frame(width: 4, height: 4)
                                    }
                                }
                                .frame(height: 4)
                            }
                            .frame(width: 50, height: 70)
                            .background(isSelected(date) ? AppTheme.almond : (isToday(date) ? Color.white : Color.clear))
                            .cornerRadius(12)
                            .shadow(color: (isToday(date) || isSelected(date)) ? AppTheme.shadow : .clear, radius: 4, y: 2)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(isSelected(date) ? AppTheme.almond : (isToday(date) ? AppTheme.almond.opacity(0.3) : Color.clear), lineWidth: isSelected(date) ? 2 : 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
        }
        .glassCard()
    }
    
    func isToday(_ date: Date) -> Bool {
        Calendar.current.isDateInToday(date)
    }
    
    func isSelected(_ date: Date) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: date)
    }
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        ContentCalendarView(posts: [], selectedDate: .constant(nil))
            .padding()
    }
}
