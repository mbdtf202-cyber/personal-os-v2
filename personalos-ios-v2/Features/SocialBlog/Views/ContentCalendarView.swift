import SwiftUI

struct ContentCalendarView: View {
    let days: [Date] = (0..<7).map { Date().addingTimeInterval(Double($0) * 86400) }
    var posts: [SocialPost]
    
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
                        VStack(spacing: 8) {
                            Text(date.formatted(.dateTime.weekday(.abbreviated)))
                                .font(.caption2)
                                .textCase(.uppercase)
                                .foregroundStyle(AppTheme.secondaryText)
                            Text(date.formatted(.dateTime.day()))
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(isToday(date) ? AppTheme.primaryText : AppTheme.secondaryText)
                            
                            // Dots for posts
                            HStack(spacing: 2) {
                                let dayPosts = posts.filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
                                ForEach(dayPosts.prefix(3)) { post in
                                    Circle()
                                        .fill(post.platform.color)
                                        .frame(width: 4, height: 4)
                                }
                            }
                            .frame(height: 4)
                        }
                        .frame(width: 50, height: 70)
                        .background(isToday(date) ? Color.white : Color.clear)
                        .cornerRadius(12)
                        .shadow(color: isToday(date) ? AppTheme.shadow : .clear, radius: 4, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isToday(date) ? AppTheme.almond : Color.clear, lineWidth: 1)
                        )
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
}

#Preview {
    ZStack {
        AppTheme.background.ignoresSafeArea()
        ContentCalendarView(posts: [])
            .padding()
    }
}
