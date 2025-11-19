import SwiftUI

/// 加载视图
struct LoadingView: View {
    var message: String = "加载中..."
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: MorandiColors.primary))
                .scaleEffect(1.5)
            
            Text(message)
                .font(Typography.bodySmall)
                .foregroundColor(MorandiColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(MorandiColors.background.opacity(0.8))
    }
}

#Preview {
    LoadingView()
}
