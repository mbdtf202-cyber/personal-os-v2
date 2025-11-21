import SwiftUI

struct SocialEmptyStateView: View {
    let message: String
    
    var body: some View {
        HStack {
            Image(systemName: "tray")
                .foregroundStyle(AppTheme.tertiaryText)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}
