import SwiftUI

struct PostRowView: View {
    let post: SocialPost
    
    var body: some View {
        HStack(spacing: 12) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 6) {
                Text(post.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppTheme.primaryText)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    platformBadge
                    
                    Text(post.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(AppTheme.tertiaryText)
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var statusIcon: some View {
        Image(systemName: statusIconName)
            .font(.title3)
            .foregroundStyle(statusColor)
            .frame(width: 40, height: 40)
            .background(statusColor.opacity(0.15))
            .clipShape(Circle())
    }
    
    private var statusIconName: String {
        switch post.status {
        case .idea: return "lightbulb.fill"
        case .draft: return "doc.text.fill"
        case .scheduled: return "clock.fill"
        case .published: return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch post.status {
        case .idea: return AppTheme.almond
        case .draft: return AppTheme.lavender
        case .scheduled: return AppTheme.mistBlue
        case .published: return AppTheme.matcha
        }
    }
    
    private var platformBadge: some View {
        Text(post.platform.rawValue)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(platformColor.opacity(0.2))
            .foregroundStyle(platformColor)
            .clipShape(Capsule())
    }
    
    private var platformColor: Color {
        switch post.platform {
        case .twitter: return .blue
        case .linkedin: return .blue
        case .medium: return .green
        case .blog: return .purple
        }
    }
}
