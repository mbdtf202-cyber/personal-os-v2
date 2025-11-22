import SwiftUI

struct NewsHeader: View {
    @Binding var selectedCategory: String
    let categories: [String]
    let onRefresh: () async -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    CategoryChip(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        withAnimation {
                            selectedCategory = category
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
        }
        .background(AppTheme.background)
    }
}

struct CategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? AppTheme.mistBlue : Color.white)
                .foregroundStyle(isSelected ? .white : AppTheme.primaryText)
                .cornerRadius(20)
                .shadow(color: AppTheme.shadow, radius: isSelected ? 4 : 2, y: 2)
        }
    }
}
