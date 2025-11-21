import SwiftUI

struct SocialStatsHeader: View {
    let totalViews: String
    let engagementRate: String
    let totalPosts: Int
    
    var body: some View {
        HStack(spacing: 16) {
            StatCard(title: "Total Views", value: totalViews, icon: "eye.fill", color: AppTheme.mistBlue)
            StatCard(title: "Engagement", value: engagementRate, icon: "heart.fill", color: AppTheme.coral)
            StatCard(title: "Posts", value: "\(totalPosts)", icon: "doc.text.fill", color: AppTheme.lavender)
        }
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(AppTheme.primaryText)
            Text(title)
                .font(.caption2)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}
