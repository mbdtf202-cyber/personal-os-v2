import SwiftUI

struct PublishedPostRow: View {
    @Bindable var post: SocialPost
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(post.platform.color.opacity(0.1))
                        .frame(width: 36, height: 36)
                    Image(systemName: post.platform.icon)
                        .font(.caption)
                        .foregroundStyle(post.platform.color)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title.isEmpty ? "Untitled Post" : post.title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(AppTheme.primaryText)
                        .lineLimit(1)
                    Text(post.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(AppTheme.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(AppTheme.tertiaryText)
            }
            
            HStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "eye.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.mistBlue)
                    TextField("Views", value: $post.views, format: .number)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.coral)
                    TextField("Likes", value: $post.likes, format: .number)
                        .font(.caption)
                        .foregroundStyle(AppTheme.secondaryText)
                        .keyboardType(.numberPad)
                        .frame(width: 60)
                }
                
                Spacer()
                
                if post.views > 0 {
                    Text("\((Double(post.likes) / Double(post.views) * 100), specifier: "%.1f")% engagement")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.matcha)
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: AppTheme.shadow, radius: 5, y: 2)
    }
}
