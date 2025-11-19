import SwiftUI

/// 空状态视图
struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(MorandiColors.textTertiary)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(Typography.headlineSmall)
                    .foregroundColor(MorandiColors.textPrimary)
                
                Text(message)
                    .font(Typography.bodySmall)
                    .foregroundColor(MorandiColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle = actionTitle, let action = action {
                PrimaryButton(title: actionTitle, action: action, style: .outline)
                    .frame(maxWidth: 200)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(
        icon: "tray",
        title: "暂无数据",
        message: "还没有任何记录，点击下方按钮开始添加",
        actionTitle: "添加记录",
        action: {}
    )
    .background(MorandiColors.background)
}
