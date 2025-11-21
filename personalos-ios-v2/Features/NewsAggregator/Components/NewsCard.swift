import SwiftUI

struct NewsCard: View {
    let article: NewsArticle
    let isBookmarked: Bool
    let onBookmark: () async -> Void
    let onCreateTask: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(article.source.name)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.mistBlue)
                
                Spacer()
                
                Text(article.publishedAt, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(AppTheme.secondaryText)
            }
            
            Text(article.title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText)
                .lineLimit(3)
            
            if let description = article.description, !description.isEmpty {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.secondaryText)
                    .lineLimit(3)
            }
            
            if let urlToImage = article.urlToImage, !urlToImage.isEmpty {
                AsyncImage(url: URL(string: urlToImage)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(AppTheme.background)
                        .overlay {
                            ProgressView()
                        }
                }
                .frame(height: 120)
                .cornerRadius(8)
                .clipped()
            }
            
            HStack {
                Button(action: {
                    Task {
                        await onBookmark()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        Text(isBookmarked ? "Saved" : "Save")
                    }
                    .font(.caption)
                    .foregroundStyle(isBookmarked ? AppTheme.coral : AppTheme.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    Task {
                        await onCreateTask()
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle")
                        Text("Task")
                    }
                    .font(.caption)
                    .foregroundStyle(AppTheme.matcha)
                }
                
                if let url = article.url {
                    Link(destination: URL(string: url)!) {
                        HStack(spacing: 4) {
                            Image(systemName: "safari")
                            Text("Read")
                        }
                        .font(.caption)
                        .foregroundStyle(AppTheme.mistBlue)
                    }
                }
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
