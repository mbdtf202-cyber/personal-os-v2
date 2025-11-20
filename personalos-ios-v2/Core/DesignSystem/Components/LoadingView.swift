import SwiftUI

/// 加载视图
struct LoadingView: View {
    var message: String = "Loading..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: AppTheme.mistBlue))
                .scaleEffect(1.5)
            
            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppTheme.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppTheme.background.opacity(0.8))
    }
}

#Preview {
    LoadingView()
}
