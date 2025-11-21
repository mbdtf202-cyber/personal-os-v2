import SwiftUI

struct SocialSectionHeader: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(AppTheme.primaryText)
            Spacer()
        }
        .padding(.horizontal)
    }
}
