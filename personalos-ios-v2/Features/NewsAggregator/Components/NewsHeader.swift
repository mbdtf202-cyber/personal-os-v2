import SwiftUI

struct NewsHeader: View {
    @Binding var selectedCategory: String
    let categories: [String]
    let onRefresh: () async -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(L.News.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(AppTheme.primaryText)
                
                Spacer()
                
                Button(action: {
                    Task {
                        await onRefresh()
                    }
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.title2)
                        .foregroundStyle(AppTheme.primaryText)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(categories, id: \.self) { category in
                        CategoryChip(
                            title: category,
                            isSelected: selectedCategory == category
                        ) {
                            selectedCategory = category
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .padding(.horizontal)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.mistBlue : AppTheme.cardBackground)
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .cornerRadius(20)
        }
    }
}
